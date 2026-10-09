//! Exercise the actual binary against an isolated public-API mock, never a
//! user's live Herdr server. No shell hooks or Herdr installation required.
use serde_json::{Value, json};
use std::fs;
use std::io::{BufRead, BufReader, Write};
use std::os::unix::net::{UnixListener, UnixStream};
use std::path::PathBuf;
use std::process::{Child, Command, Stdio};
use std::sync::{
    Arc, Mutex,
    atomic::{AtomicBool, AtomicU64, Ordering},
};
use std::thread;
use std::time::{Duration, Instant};

static NEXT: AtomicU64 = AtomicU64::new(0);

struct Server {
    root: PathBuf,
    socket: PathBuf,
    snapshot: Arc<Mutex<Value>>,
    subscribers: Arc<Mutex<Vec<UnixStream>>>,
    program: Arc<Mutex<String>>,
    before_get: Arc<Mutex<Option<String>>>,
    requests: Arc<Mutex<std::collections::HashMap<String, usize>>>,
    stop: Arc<AtomicBool>,
    thread: Option<thread::JoinHandle<()>>,
}

impl Server {
    fn new() -> Self {
        let root = std::env::temp_dir().join(format!(
            "autoname-test-{}-{}",
            std::process::id(),
            NEXT.fetch_add(1, Ordering::Relaxed)
        ));
        fs::create_dir_all(&root).unwrap();
        let config = root.join("config/herdr");
        fs::create_dir_all(&config).unwrap();
        let socket = config.join("herdr.sock");
        let listener = UnixListener::bind(&socket).unwrap();
        listener.set_nonblocking(true).unwrap();
        let snapshot = Arc::new(Mutex::new(json!({
            "workspaces": [], "agents": [],
            "tabs": [{"tab_id": "w1:t1", "workspace_id": "w1", "label": "1", "focused": true}],
            "panes": [{"pane_id": "w1:p1", "tab_id": "w1:t1", "agent": "opencode", "agent_status": "working", "terminal_title_stripped": "First task"}],
            "layouts": [{"tab_id": "w1:t1", "focused_pane_id": "w1:p1"}]
        })));
        let subscribers = Arc::new(Mutex::new(Vec::<UnixStream>::new()));
        let program = Arc::new(Mutex::new("zsh".to_string()));
        let before_get = Arc::new(Mutex::new(None::<String>));
        let requests = Arc::new(Mutex::new(std::collections::HashMap::<String, usize>::new()));
        let counts = requests.clone();
        let stop = Arc::new(AtomicBool::new(false));
        let (data, clients, executable, stopped) = (
            snapshot.clone(),
            subscribers.clone(),
            program.clone(),
            stop.clone(),
        );
        let rename_before_get = before_get.clone();
        let thread = thread::spawn(move || {
            while !stopped.load(Ordering::Relaxed) {
                let (mut stream, _) = match listener.accept() {
                    Ok(pair) => pair,
                    Err(error) if error.kind() == std::io::ErrorKind::WouldBlock => {
                        thread::sleep(Duration::from_millis(5));
                        continue;
                    }
                    Err(error) => panic!("accept: {error}"),
                };
                stream
                    .set_read_timeout(Some(Duration::from_secs(2)))
                    .unwrap();
                let mut line = String::new();
                BufReader::new(stream.try_clone().unwrap())
                    .read_line(&mut line)
                    .unwrap();
                let request: Value = serde_json::from_str(&line).unwrap();
                let params = &request["params"];
                *counts
                    .lock()
                    .unwrap()
                    .entry(request["method"].as_str().unwrap().into())
                    .or_default() += 1;
                let response = match request["method"].as_str().unwrap() {
                    "events.subscribe" => {
                        for subscription in params["subscriptions"].as_array().unwrap() {
                            if matches!(
                                subscription["type"].as_str(),
                                Some(
                                    "pane.agent_status_changed"
                                        | "pane.scroll_changed"
                                        | "pane.output_matched"
                                )
                            ) {
                                assert!(
                                    subscription.get("pane_id").is_some(),
                                    "Herdr requires pane_id for {subscription}"
                                );
                            }
                        }
                        json!({"type": "subscription_started"})
                    }
                    "session.snapshot" => json!({"snapshot": *data.lock().unwrap()}),
                    "tab.get" => {
                        let mut data = data.lock().unwrap();
                        let tab = data["tabs"]
                            .as_array_mut()
                            .unwrap()
                            .iter_mut()
                            .find(|tab| tab["tab_id"] == params["tab_id"])
                            .unwrap();
                        if let Some(label) = rename_before_get.lock().unwrap().take() {
                            tab["label"] = json!(label);
                            broadcast(
                                &clients,
                                json!({"event": "tab.renamed", "data": {"tab_id": tab["tab_id"], "label": tab["label"]}}),
                            );
                        }
                        json!({"tab": tab})
                    }
                    "tab.list" => json!({"tabs": data.lock().unwrap()["tabs"]}),
                    "tab.rename" => {
                        let mut snapshot = data.lock().unwrap();
                        let tab = snapshot["tabs"]
                            .as_array_mut()
                            .unwrap()
                            .iter_mut()
                            .find(|tab| tab["tab_id"] == params["tab_id"])
                            .unwrap();
                        tab["label"] = params["label"].clone();
                        broadcast(
                            &clients,
                            json!({"event": "tab.renamed", "data": {"tab_id": tab["tab_id"], "label": tab["label"]}}),
                        );
                        json!({"tab": tab})
                    }
                    "pane.process_info" => {
                        json!({"process_info": {"foreground_process_group_id": 1, "foreground_processes": [{"pid": 1, "argv0": *executable.lock().unwrap()}]}})
                    }
                    "workspace.report_metadata" | "pane.report_metadata" => {
                        let (list, field) = if request["method"] == "workspace.report_metadata" {
                            ("workspaces", "workspace_id")
                        } else {
                            ("agents", "pane_id")
                        };
                        let mut data = data.lock().unwrap();
                        let resource = data[list]
                            .as_array_mut()
                            .unwrap()
                            .iter_mut()
                            .find(|resource| resource[field] == params[field])
                            .unwrap();
                        let tokens = resource["tokens"].as_object_mut().unwrap();
                        for (key, value) in params["tokens"].as_object().unwrap() {
                            if value.is_null() {
                                tokens.remove(key);
                            } else {
                                tokens.insert(key.clone(), value.clone());
                            }
                        }
                        json!({"type": "metadata_updated"})
                    }
                    method => panic!("unexpected method {method}"),
                };
                writeln!(
                    stream,
                    "{}",
                    json!({"id": request["id"], "result": response})
                )
                .unwrap();
                if request["method"] == "events.subscribe" {
                    clients.lock().unwrap().push(stream);
                }
            }
        });
        Self {
            root,
            socket,
            snapshot,
            subscribers,
            program,
            before_get,
            requests,
            stop,
            thread: Some(thread),
        }
    }

    fn command(&self) -> Command {
        let mut command = Command::new(env!("CARGO_BIN_EXE_herdr-autoname"));
        command
            .env("HERDR_SOCKET_PATH", &self.socket)
            .env("SHELL", "/bin/zsh")
            .env("HERDR_AUTONAME_INDEXES", "grouped")
            .env("HOME", &self.root)
            .env("XDG_CONFIG_HOME", self.root.join("config"))
            .env("XDG_STATE_HOME", self.root.join("state"))
            .env_remove("HERDR_SESSION")
            .env_remove("HERDR_CONFIG_PATH")
            .env_remove("HERDR_TAB_ID")
            .env_remove("HERDR_PLUGIN_CONTEXT_JSON");
        command
    }

    fn watch(&self) -> Watcher {
        Watcher(
            self.command()
                .arg("watch")
                .stdout(Stdio::null())
                .spawn()
                .unwrap(),
        )
    }

    fn label(&self) -> String {
        self.snapshot.lock().unwrap()["tabs"][0]["label"]
            .as_str()
            .unwrap()
            .to_string()
    }

    fn wait_label(&self, expected: &str) {
        let deadline = Instant::now() + Duration::from_secs(5);
        while self.label() != expected {
            assert!(
                Instant::now() < deadline,
                "expected {expected:?}, got {:?}",
                self.label()
            );
            thread::sleep(Duration::from_millis(20));
        }
    }

    fn title_event(&self, title: &str) {
        let pane = {
            let mut data = self.snapshot.lock().unwrap();
            data["panes"][0]["terminal_title_stripped"] = json!(title);
            data["panes"][0].clone()
        };
        let event = json!({"event": "pane.updated", "data": {"pane": pane}});
        self.subscribers
            .lock()
            .unwrap()
            .retain_mut(|stream| writeln!(stream, "{event}").is_ok());
    }
}

fn broadcast(subscribers: &Mutex<Vec<UnixStream>>, event: Value) {
    subscribers
        .lock()
        .unwrap()
        .retain_mut(|stream| writeln!(stream, "{event}").is_ok());
}

impl Drop for Server {
    fn drop(&mut self) {
        self.stop.store(true, Ordering::Relaxed);
        self.thread.take().unwrap().join().unwrap();
        fs::remove_dir_all(&self.root).unwrap();
    }
}

struct Watcher(Child);
impl Drop for Watcher {
    fn drop(&mut self) {
        let _ = self.0.kill();
        let _ = self.0.wait();
    }
}

#[test]
fn titles_manual_renames_reset_and_restart() {
    let server = Server::new();
    let watcher = server.watch();
    server.wait_label("[1] First task");
    server.title_event("Second task");
    server.wait_label("[1] Second task");
    server.snapshot.lock().unwrap()["tabs"][0]["label"] = json!("My manual name");
    server.title_event("Third task");
    server.wait_label("[1] My manual name");
    thread::sleep(Duration::from_millis(1200));
    assert_eq!(server.label(), "[1] My manual name");
    assert!(
        server
            .command()
            .args(["reset", "w1:t1"])
            .status()
            .unwrap()
            .success()
    );
    server.wait_label("[1] Third task");
    drop(watcher);
    let _watcher = server.watch();
    server.title_event("Fourth task");
    server.wait_label("[1] Fourth task");
}

#[test]
fn foreground_changes_without_any_event() {
    let server = Server::new();
    {
        let mut data = server.snapshot.lock().unwrap();
        data["panes"][0]["agent"] = Value::Null;
        data["panes"][0]["terminal_title_stripped"] = Value::Null;
    }
    let _watcher = server.watch();
    server.wait_label("[1] zsh");
    *server.program.lock().unwrap() = "nvim".into();
    server.wait_label("[1] nvim");
    *server.program.lock().unwrap() = "zsh".into();
    server.wait_label("[1] zsh");
}

#[test]
fn sessions_do_not_erase_each_others_ownership() {
    let first = Server::new();
    let second = Server::new();
    // Same user/state root, same public IDs, different socket identities.
    let _first = first.watch();
    let _second = Watcher(
        second
            .command()
            .env("XDG_STATE_HOME", first.root.join("state"))
            .arg("watch")
            .spawn()
            .unwrap(),
    );
    first.wait_label("[1] First task");
    second.wait_label("[1] First task");
    first.title_event("One");
    second.title_event("Two");
    first.wait_label("[1] One");
    second.wait_label("[1] Two");
}

#[test]
fn lost_events_reconnect_and_read_authoritative_state() {
    let server = Server::new();
    let _watcher = server.watch();
    server.wait_label("[1] First task");
    for stream in server.subscribers.lock().unwrap().iter_mut() {
        writeln!(
            stream,
            "{}",
            json!({"id": "autoname", "error": {"code": "events_lost", "message": "overrun"}})
        )
        .unwrap();
    }
    server.subscribers.lock().unwrap().clear();
    server.snapshot.lock().unwrap()["panes"][0]["terminal_title_stripped"] = json!("Recovered");
    server.wait_label("[1] Recovered");
}

#[test]
fn reorder_and_close_follow_positions_not_public_numbers() {
    let server = Server::new();
    {
        let mut data = server.snapshot.lock().unwrap();
        data["tabs"]
            .as_array_mut()
            .unwrap()
            .push(json!({"tab_id": "w1:tZ", "workspace_id": "w1", "label": "99"}));
        data["panes"].as_array_mut().unwrap().push(json!({"pane_id": "w1:pZ", "tab_id": "w1:tZ", "agent": "claude", "terminal_title_stripped": "Other task"}));
    }
    let _watcher = server.watch();
    server.wait_label("[1] First task");
    let deadline = Instant::now() + Duration::from_secs(5);
    while server.snapshot.lock().unwrap()["tabs"][1]["label"] != "[2] Other task" {
        assert!(Instant::now() < deadline);
        thread::sleep(Duration::from_millis(20));
    }
    server.snapshot.lock().unwrap()["tabs"]
        .as_array_mut()
        .unwrap()
        .swap(0, 1);
    broadcast(
        &server.subscribers,
        json!({"event": "tab.moved", "data": {"tab_id": "w1:tZ"}}),
    );
    server.wait_label("[1] Other task");
    {
        let mut data = server.snapshot.lock().unwrap();
        data["tabs"].as_array_mut().unwrap().remove(0);
        data["panes"]
            .as_array_mut()
            .unwrap()
            .retain(|pane| pane["tab_id"] == "w1:t1");
    }
    broadcast(
        &server.subscribers,
        json!({"event": "tab.closed", "data": {"tab_id": "w1:tZ"}}),
    );
    server.wait_label("[1] First task");
}

#[test]
fn corrupted_ownership_is_reported_not_discarded() {
    let server = Server::new();
    let watcher = server.watch();
    server.wait_label("[1] First task");
    drop(watcher);
    let sessions = server.root.join("state/herdr-autoname/sessions");
    let namespace = fs::read_dir(sessions)
        .unwrap()
        .next()
        .unwrap()
        .unwrap()
        .path();
    fs::write(namespace.join("state.json"), "not valid json").unwrap();
    let output = server.command().arg("event").output().unwrap();
    assert!(!output.status.success());
    assert!(String::from_utf8_lossy(&output.stderr).contains("refusing to discard ownership"));
    assert_eq!(server.label(), "[1] First task");
}

#[test]
fn duplicate_watchers_are_rejected() {
    let server = Server::new();
    let _watcher = server.watch();
    server.wait_label("[1] First task");
    let output = server.command().arg("watch").output().unwrap();
    assert!(!output.status.success());
    assert!(String::from_utf8_lossy(&output.stderr).contains("another watcher"));
}

#[test]
fn manual_change_after_snapshot_wins_preflight() {
    let server = Server::new();
    let _watcher = server.watch();
    server.wait_label("[1] First task");
    *server.before_get.lock().unwrap() = Some("Manual during refresh".into());
    server.title_event("Would otherwise overwrite");
    server.wait_label("[1] Manual during refresh");
    thread::sleep(Duration::from_millis(1200));
    assert_eq!(server.label(), "[1] Manual during refresh");
}

#[test]
fn event_bursts_converge_and_session_disconnect_exits() {
    let server = Server::new();
    let mut watcher = server.watch();
    server.wait_label("[1] First task");
    for index in 0..100 {
        server.title_event(&format!("Task {index}"));
    }
    server.wait_label("[1] Task 99");
    server.subscribers.lock().unwrap().clear();
    let deadline = Instant::now() + Duration::from_secs(5);
    while watcher.0.try_wait().unwrap().is_none() {
        assert!(Instant::now() < deadline, "watcher outlived session socket");
        thread::sleep(Duration::from_millis(20));
    }
}

#[test]
fn startup_returns_without_blocking_and_is_idempotent() {
    let server = Server::new();
    let mut hook = server.command().arg("start").spawn().unwrap();
    let deadline = Instant::now() + Duration::from_secs(3);
    loop {
        if let Some(status) = hook.try_wait().unwrap() {
            assert!(status.success());
            break;
        }
        assert!(Instant::now() < deadline, "startup hook blocked");
        thread::sleep(Duration::from_millis(20));
    }
    server.wait_label("[1] First task");
    assert!(server.command().arg("start").status().unwrap().success());
    thread::sleep(Duration::from_millis(200));
    assert_eq!(server.requests.lock().unwrap()["events.subscribe"], 1);
    server.subscribers.lock().unwrap().clear();
    let sessions = server.root.join("state/herdr-autoname/sessions");
    let namespace = fs::read_dir(sessions)
        .unwrap()
        .next()
        .unwrap()
        .unwrap()
        .path();
    let lock = fs::OpenOptions::new()
        .read(true)
        .write(true)
        .open(namespace.join("watch.lock"))
        .unwrap();
    let deadline = Instant::now() + Duration::from_secs(3);
    while fs2::FileExt::try_lock_exclusive(&lock).is_err() {
        assert!(Instant::now() < deadline, "child did not release its lock");
        thread::sleep(Duration::from_millis(20));
    }
}

#[test]
fn index_metadata_uses_public_token_patches_and_can_be_disabled() {
    let server = Server::new();
    {
        let mut data = server.snapshot.lock().unwrap();
        data["workspaces"] = json!([{"workspace_id": "w1", "tokens": {}}]);
        data["agents"] = json!([{"pane_id": "w1:p1", "tokens": {}}]);
    }
    let watcher = server.watch();
    server.wait_label("[1] First task");
    {
        let data = server.snapshot.lock().unwrap();
        assert_eq!(data["workspaces"][0]["tokens"]["autoname_index"], "1");
        assert_eq!(data["agents"][0]["tokens"]["autoname_index"], "1");
    }
    drop(watcher);
    assert!(
        server
            .command()
            .env("HERDR_AUTONAME_INDEXES", "off")
            .arg("event")
            .status()
            .unwrap()
            .success()
    );
    let data = server.snapshot.lock().unwrap();
    assert!(
        data["workspaces"][0]["tokens"]
            .as_object()
            .unwrap()
            .is_empty()
    );
    assert!(data["agents"][0]["tokens"].as_object().unwrap().is_empty());
    assert_eq!(data["tabs"][0]["label"], "[1] First task");
}

#[test]
fn legacy_default_ownership_is_migrated_without_modifying_original() {
    let server = Server::new();
    server.snapshot.lock().unwrap()["tabs"][0]["label"] = json!("[1] Old task");
    let legacy_dir = server.root.join("state/herdr-autoname");
    fs::create_dir_all(&legacy_dir).unwrap();
    let legacy = json!({"tabs": {"w1:t1": "Old task"}}).to_string();
    fs::write(legacy_dir.join("state.json"), &legacy).unwrap();
    let _watcher = server.watch();
    server.wait_label("[1] First task");
    assert_eq!(
        fs::read_to_string(legacy_dir.join("state.json")).unwrap(),
        legacy
    );
}

#[test]
fn a_hundred_agent_tabs_have_no_idle_api_traffic() {
    let server = Server::new();
    {
        let mut data = server.snapshot.lock().unwrap();
        data["tabs"] = json!((0..100).map(|i| json!({"tab_id": format!("w1:t{i}"), "workspace_id": "w1", "label": if i < 9 { format!("[{}] Task {i}", i + 1) } else { format!("Task {i}") }})).collect::<Vec<_>>());
        data["panes"] = json!((0..100).map(|i| json!({"pane_id": format!("w1:p{i}"), "tab_id": format!("w1:t{i}"), "agent": "opencode", "terminal_title_stripped": format!("Task {i}")})).collect::<Vec<_>>());
        data["layouts"] = json!([]);
    }
    let legacy_dir = server.root.join("state/herdr-autoname");
    fs::create_dir_all(&legacy_dir).unwrap();
    let owners: serde_json::Map<_, _> = (0..100)
        .map(|i| (format!("w1:t{i}"), json!(format!("Task {i}"))))
        .collect();
    fs::write(
        legacy_dir.join("state.json"),
        json!({"tabs": owners}).to_string(),
    )
    .unwrap();
    let _watcher = server.watch();
    let deadline = Instant::now() + Duration::from_secs(10);
    while !server
        .requests
        .lock()
        .unwrap()
        .contains_key("session.snapshot")
    {
        assert!(Instant::now() < deadline);
        thread::sleep(Duration::from_millis(20));
    }
    thread::sleep(Duration::from_millis(300));
    let before = server.requests.lock().unwrap().clone();
    thread::sleep(Duration::from_secs(3));
    assert_eq!(
        *server.requests.lock().unwrap(),
        before,
        "idle agent tabs must not cause polling"
    );
    assert!(!before.contains_key("pane.process_info"));
}

#[test]
fn foreground_polling_does_not_refresh_the_whole_session() {
    let server = Server::new();
    server.snapshot.lock().unwrap()["panes"][0]["agent"] = Value::Null;
    let _watcher = server.watch();
    server.wait_label("[1] zsh");
    thread::sleep(Duration::from_millis(300));
    let snapshots = server.requests.lock().unwrap()["session.snapshot"];
    let process_reads = server.requests.lock().unwrap()["pane.process_info"];
    thread::sleep(Duration::from_millis(4300));
    let requests = server.requests.lock().unwrap();
    assert_eq!(requests["session.snapshot"], snapshots);
    let checks = requests["pane.process_info"] - process_reads;
    assert!(
        (1..=3).contains(&checks),
        "unexpected process polling rate: {checks}"
    );
}
