//! Focused Herdr navigation labels for Ben's configuration.
//!
//! - Workspaces and agents publish a bare 1-9 jump-key number as display-only
//!   metadata (`$autoname_index`).
//! - Tabs are named after the relevant pane's agent task or foreground program
//!   and retain an `[N]` jump-key prefix.
//! - A tab renamed by hand opts out of automatic naming, while numbering still
//!   follows tab order.
//!
//! Herdr 0.9.3 baseline. A supervised socket subscriber handles live titles;
//! bounded polling covers foreground programs without shell hooks.

mod api;
mod state;

use anyhow::{Context, Result, bail};
use fs2::FileExt;
use serde::Deserialize;
use serde_json::{Value, json};
use state::{State, TabState};
use std::cell::RefCell;
use std::collections::{BTreeMap, HashMap, HashSet};
use std::fs::{self, OpenOptions};
use std::os::fd::AsFd;
use std::os::unix::process::CommandExt;
use std::path::{Path, PathBuf};
use std::process::{Command, Stdio};
use std::sync::OnceLock;
use std::time::{Duration, Instant};

static SOCKET: OnceLock<PathBuf> = OnceLock::new();
thread_local! {
    static PROGRAMS: RefCell<HashMap<String, (Instant, Option<String>)>> = RefCell::new(HashMap::new());
}

const INDEX_TOKEN: &str = "autoname_index";
const METADATA_SOURCE: &str = "herdr-autoname";
const MAX_NAME_LEN: usize = 20;
const MAX_TITLE_LEN: usize = 28;
const FOREGROUND_INTERVAL: Duration = Duration::from_secs(2);

#[derive(Debug, Default, Deserialize)]
struct Snapshot {
    workspaces: Vec<Workspace>,
    tabs: Vec<Tab>,
    panes: Vec<Pane>,
    agents: Vec<Agent>,
    layouts: Vec<Layout>,
}

#[derive(Debug, Default, Deserialize)]
struct Workspace {
    workspace_id: String,
    #[serde(default)]
    tokens: HashMap<String, String>,
    worktree: Option<Worktree>,
}

#[derive(Debug, Deserialize)]
struct Worktree {
    repo_key: String,
    #[serde(default)]
    is_linked_worktree: bool,
}

#[derive(Debug, Default, Deserialize)]
struct Tab {
    tab_id: String,
    workspace_id: String,
    #[serde(default)]
    label: String,
}

#[derive(Debug, Default, Deserialize, PartialEq, Eq)]
struct Pane {
    pane_id: String,
    tab_id: String,
    agent: Option<String>,
    agent_status: Option<String>,
    terminal_title: Option<String>,
    terminal_title_stripped: Option<String>,
    cwd: Option<String>,
    foreground_cwd: Option<String>,
}

#[derive(Debug, Default, Deserialize)]
struct Agent {
    pane_id: String,
    #[serde(default)]
    tokens: HashMap<String, String>,
}

#[derive(Debug, Default, Deserialize)]
struct Layout {
    tab_id: String,
    focused_pane_id: Option<String>,
}

#[derive(Debug, Default, Deserialize)]
struct LegacyState {
    #[serde(default)]
    tabs: BTreeMap<String, String>,
}

#[derive(Debug, Default, Deserialize)]
struct ProcessInfo {
    foreground_process_group_id: Option<u64>,
    #[serde(default)]
    foreground_processes: Vec<Process>,
}

#[derive(Debug, Default, Deserialize)]
struct Process {
    pid: u64,
    argv0: Option<String>,
    #[serde(default)]
    argv: Vec<String>,
    name: Option<String>,
}

fn main() -> Result<()> {
    let args: Vec<_> = std::env::args().skip(1).collect();
    let mode = args.first().map(String::as_str).unwrap_or("event");
    let session = args
        .iter()
        .position(|arg| arg == "--session")
        .map(|index| args.get(index + 1).context("--session needs a name"))
        .transpose()?;
    SOCKET
        .set(resolve_socket(session.map(String::as_str))?)
        .expect("initialize socket once");
    match mode {
        "start" => start(),
        "watch" => watch(false),
        "watch-child" => watch(true),
        "event" => reconcile_once(None, false).map(|_| ()),
        "reset" => {
            let explicit = args.get(1).filter(|arg| !arg.starts_with("--"));
            reconcile_once(explicit.map(String::as_str), true).map(|_| ())
        }
        _ => bail!("usage: herdr-autoname [start|watch|event|reset [TAB_ID]] [--session NAME]"),
    }
}

fn open_lock(name: &str) -> Result<fs::File> {
    let state_dir = state_dir();
    fs::create_dir_all(&state_dir).with_context(|| format!("create {}", state_dir.display()))?;
    let lock_path = state_dir.join(name);
    let lock = OpenOptions::new()
        .create(true)
        .truncate(false)
        .read(true)
        .write(true)
        .open(&lock_path)
        .with_context(|| format!("open {}", lock_path.display()))?;
    Ok(lock)
}

fn reconcile_once(target: Option<&str>, reset: bool) -> Result<(Snapshot, HashSet<String>)> {
    let lock = open_lock("lock")?;
    lock.lock_exclusive().context("lock plugin state")?;
    let mut snapshot = read_snapshot()?;
    let force = if reset {
        let target = target
            .map(str::to_owned)
            .or_else(|| reset_target(&snapshot))
            .context("no reset target; pass a tab id explicitly")?;
        if !snapshot.tabs.iter().any(|tab| tab.tab_id == target) {
            bail!("reset target {target} does not exist in this session");
        }
        Some(target)
    } else {
        None
    };
    let mut foreground_tabs = HashSet::new();
    reconcile(&mut snapshot, force.as_deref(), &mut foreground_tabs)?;
    Ok((snapshot, foreground_tabs))
}

fn socket_path() -> PathBuf {
    SOCKET
        .get()
        .cloned()
        .unwrap_or_else(|| resolve_socket(None).expect("valid session"))
}

fn resolve_socket(explicit: Option<&str>) -> Result<PathBuf> {
    if explicit.is_none()
        && let Some(path) = std::env::var_os("HERDR_SOCKET_PATH")
    {
        return Ok(PathBuf::from(path));
    }
    // Match Herdr's config_dir(), not its optional config *file* override:
    // HERDR_CONFIG_PATH does not relocate the server socket.
    let config = std::env::var_os("XDG_CONFIG_HOME")
        .map(PathBuf::from)
        .unwrap_or_else(|| home_dir().join(".config"))
        .join("herdr");
    let env_session = std::env::var("HERDR_SESSION").ok();
    let session = explicit.or(env_session.as_deref()).unwrap_or("default");
    if session.is_empty()
        || session.len() > 64
        || matches!(session, "." | "..")
        || !session
            .bytes()
            .all(|c| c.is_ascii_alphanumeric() || matches!(c, b'.' | b'-' | b'_'))
    {
        bail!("invalid session name {session:?}");
    }
    Ok(if session == "default" {
        config.join("herdr.sock")
    } else {
        config.join("sessions").join(session).join("herdr.sock")
    })
}

fn request(method: &str, params: Value) -> Result<Value> {
    api::request(&socket_path(), method, params).with_context(|| format!("Herdr {method}"))
}

fn read_snapshot() -> Result<Snapshot> {
    let value = request("session.snapshot", json!({}))?;
    let snapshot: Snapshot =
        serde_json::from_value(value.get("snapshot").cloned().context("missing snapshot")?)
            .context("decode Herdr snapshot")?;
    PROGRAMS.with(|cache| {
        cache
            .borrow_mut()
            .retain(|id, _| snapshot.panes.iter().any(|pane| &pane.pane_id == id))
    });
    Ok(snapshot)
}

fn relevant_event(event: &Value, snapshot: &Snapshot) -> bool {
    if event.get("event").and_then(Value::as_str) == Some("tab.renamed") {
        return !snapshot.tabs.iter().any(|tab| {
            event.pointer("/data/tab_id").and_then(Value::as_str) == Some(tab.tab_id.as_str())
                && event.pointer("/data/label").and_then(Value::as_str) == Some(tab.label.as_str())
        });
    }
    if event.get("event").and_then(Value::as_str) == Some("pane.updated") {
        // Exclude revision, scroll, and our own index-token changes. These can
        // be frequent, but do not affect the selected title or program.
        let pane = event
            .pointer("/data/pane")
            .cloned()
            .and_then(|value| serde_json::from_value::<Pane>(value).ok());
        return pane.is_none_or(|pane| !snapshot.panes.contains(&pane));
    }
    event.get("event").is_some()
}

fn start() -> Result<()> {
    let lock = open_lock("watch.lock")?;
    match lock.try_lock_exclusive() {
        Ok(()) => {}
        Err(error) if error.kind() == std::io::ErrorKind::WouldBlock => return Ok(()),
        Err(error) => return Err(error).context("lock watcher"),
    }
    let log = OpenOptions::new()
        .create(true)
        .append(true)
        .open(state_dir().join("watch.log"))?;
    // Pass the already-held lock as stdin: the child owns it before the hook
    // exits, with no pid files, startup races, or inherited log pipes.
    Command::new(std::env::current_exe()?)
        .arg("watch-child")
        .env("HERDR_SOCKET_PATH", socket_path())
        .stdin(Stdio::from(lock))
        .stdout(Stdio::null())
        .stderr(Stdio::from(log))
        .process_group(0)
        .spawn()
        .context("start title watcher")?;
    Ok(())
}

fn watch(inherited_lock: bool) -> Result<()> {
    let _lock = if inherited_lock {
        fs::File::from(std::io::stdin().as_fd().try_clone_to_owned()?)
    } else {
        let lock = open_lock("watch.lock")?;
        lock.try_lock_exclusive()
            .context("another watcher already owns this session")?;
        lock
    };
    let mut last_error = String::new();
    loop {
        let run = || -> Result<()> {
            // Subscribe first. Events arriving during an authoritative read
            // remain queued, so a subsequent refresh cannot miss that change.
            let mut events = api::Events::subscribe(&socket_path())?;
            let (mut snapshot, mut foreground_tabs) = reconcile_once(None, false)?;
            let mut poll = Instant::now() + FOREGROUND_INTERVAL;
            let mut dirty: Option<Instant> = None;
            loop {
                // No timer or API traffic when all automatic tabs have task
                // titles. Wake only for events or an actual fallback deadline.
                let deadline = dirty
                    .into_iter()
                    .chain((!foreground_tabs.is_empty()).then_some(poll))
                    .min();
                let timeout =
                    deadline.map(|deadline| deadline.saturating_duration_since(Instant::now()));
                if let Some(event) = events.next(timeout)?
                    && relevant_event(&event, &snapshot)
                {
                    dirty.get_or_insert(Instant::now() + Duration::from_millis(75));
                }
                let now = Instant::now();
                if dirty.is_some_and(|deadline| now >= deadline) {
                    (snapshot, foreground_tabs) = reconcile_once(None, false)?;
                    poll = Instant::now() + FOREGROUND_INTERVAL;
                    dirty = None;
                } else if !foreground_tabs.is_empty() && now >= poll {
                    poll_foreground(&mut snapshot, &mut foreground_tabs)?;
                    poll = Instant::now() + FOREGROUND_INTERVAL;
                }
            }
        };
        if let Err(error) = run() {
            if error
                .chain()
                .filter_map(|cause| cause.downcast_ref::<std::io::Error>())
                .any(|error| {
                    matches!(
                        error.kind(),
                        std::io::ErrorKind::UnexpectedEof
                            | std::io::ErrorKind::ConnectionReset
                            | std::io::ErrorKind::ConnectionRefused
                            | std::io::ErrorKind::NotFound
                    )
                })
            {
                return Ok(());
            }
            let message = format!("{error:#}");
            if message != last_error {
                eprintln!("herdr-autoname: {message}; retrying in 2s");
                last_error = message;
            }
        }
        std::thread::sleep(Duration::from_secs(2));
    }
}

fn state_root() -> PathBuf {
    std::env::var_os("XDG_STATE_HOME")
        .map(PathBuf::from)
        .unwrap_or_else(|| home_dir().join(".local/state"))
}

fn state_dir() -> PathBuf {
    // Stable FNV-1a namespace; the state also verifies the full socket identity.
    let socket = socket_path();
    let hash = socket
        .as_os_str()
        .as_encoded_bytes()
        .iter()
        .fold(0xcbf29ce484222325_u64, |hash, byte| {
            (hash ^ u64::from(*byte)).wrapping_mul(0x100000001b3)
        });
    state_root()
        .join("herdr-autoname/sessions")
        .join(format!("{hash:016x}"))
}

fn home_dir() -> PathBuf {
    std::env::var_os("HOME").map_or_else(PathBuf::new, PathBuf::from)
}

fn session_dir() -> PathBuf {
    socket_path()
        .parent()
        .expect("socket has a parent")
        .to_path_buf()
}

fn reconcile(
    snapshot: &mut Snapshot,
    force_tab: Option<&str>,
    foreground_tabs: &mut HashSet<String>,
) -> Result<()> {
    reconcile_workspaces(snapshot)?;
    reconcile_agents(snapshot)?;
    reconcile_tabs(snapshot, force_tab, None, foreground_tabs)
}

fn poll_foreground(snapshot: &mut Snapshot, foreground_tabs: &mut HashSet<String>) -> Result<()> {
    let lock = open_lock("lock")?;
    lock.lock_exclusive()?;
    let targets = foreground_tabs.clone();
    for tab in &mut snapshot.tabs {
        if targets.contains(&tab.tab_id) {
            let current = request("tab.get", json!({"tab_id": tab.tab_id}))?;
            *tab = serde_json::from_value(current.get("tab").cloned().context("missing tab")?)?;
        }
    }
    reconcile_tabs(snapshot, None, Some(&targets), foreground_tabs)
}

fn reconcile_workspaces(snapshot: &Snapshot) -> Result<()> {
    let positions = visible_workspace_positions(snapshot);
    for workspace in &snapshot.workspaces {
        let current = workspace.tokens.get(INDEX_TOKEN).map(String::as_str);
        let desired = positions
            .get(&workspace.workspace_id)
            .copied()
            .filter(|position| {
                (1..=9).contains(position)
                    && std::env::var("HERDR_AUTONAME_INDEXES").as_deref() != Ok("off")
            })
            .map(|position| position.to_string());
        report_workspace_token(&workspace.workspace_id, current, desired.as_deref())?;
    }
    Ok(())
}

fn visible_workspace_positions(snapshot: &Snapshot) -> HashMap<String, usize> {
    // These are server-local, expanded-group positions, not client-specific
    // navigation promises. Do not scrape obsolete/private client state files.
    let mut by_repo: HashMap<String, Vec<usize>> = HashMap::new();
    for (index, workspace) in snapshot.workspaces.iter().enumerate() {
        if let Some(worktree) = &workspace.worktree
            && !worktree.repo_key.is_empty()
        {
            by_repo
                .entry(worktree.repo_key.clone())
                .or_default()
                .push(index);
        }
    }

    // Only 2+ checkouts with an open main checkout form a nested Space. Its
    // main checkout heads the rendered group even if a linked worktree appears
    // earlier in the raw workspace array.
    let mut groups: HashMap<String, Vec<usize>> = HashMap::new();
    for (repo, members) in by_repo {
        if members.len() < 2 {
            continue;
        }
        let Some(head) = members.iter().copied().find(|index| {
            snapshot.workspaces[*index]
                .worktree
                .as_ref()
                .is_some_and(|worktree| !worktree.is_linked_worktree)
        }) else {
            continue;
        };
        let ordered = std::iter::once(head)
            .chain(members.into_iter().filter(|index| *index != head))
            .collect();
        groups.insert(repo, ordered);
    }

    let mut order = Vec::new();
    let mut emitted = HashSet::new();
    for (index, workspace) in snapshot.workspaces.iter().enumerate() {
        let Some(worktree) = &workspace.worktree else {
            order.push(index);
            continue;
        };
        let Some(members) = groups.get(&worktree.repo_key) else {
            order.push(index);
            continue;
        };
        let render_at = *members.iter().min().expect("non-empty workspace group");
        if index != render_at || !emitted.insert(worktree.repo_key.clone()) {
            continue;
        }
        order.push(members[0]);
        order.extend(members.iter().skip(1).copied());
    }

    order
        .into_iter()
        .enumerate()
        .map(|(position, index)| {
            (
                snapshot.workspaces[index].workspace_id.clone(),
                position + 1,
            )
        })
        .collect()
}

fn reconcile_agents(snapshot: &Snapshot) -> Result<()> {
    let grouped = std::env::var("HERDR_AUTONAME_INDEXES").as_deref() != Ok("off");
    for (index, agent) in snapshot.agents.iter().enumerate() {
        let current = agent.tokens.get(INDEX_TOKEN).map(String::as_str);
        let desired = grouped
            .then_some(index + 1)
            .filter(|position| *position <= 9)
            .map(|position| position.to_string());
        report_pane_token(&agent.pane_id, current, desired.as_deref())?;
    }
    Ok(())
}

fn report_workspace_token(
    workspace_id: &str,
    current: Option<&str>,
    desired: Option<&str>,
) -> Result<()> {
    if current == desired {
        return Ok(());
    }
    request(
        "workspace.report_metadata",
        json!({
            "workspace_id": workspace_id, "source": METADATA_SOURCE,
            "tokens": {(INDEX_TOKEN): desired}
        }),
    )?;
    Ok(())
}

fn report_pane_token(pane_id: &str, current: Option<&str>, desired: Option<&str>) -> Result<()> {
    if current == desired {
        return Ok(());
    }
    request(
        "pane.report_metadata",
        json!({
            "pane_id": pane_id, "source": METADATA_SOURCE,
            "tokens": {(INDEX_TOKEN): desired}
        }),
    )?;
    Ok(())
}

fn reconcile_tabs(
    snapshot: &mut Snapshot,
    force_tab: Option<&str>,
    only: Option<&HashSet<String>>,
    foreground_tabs: &mut HashSet<String>,
) -> Result<()> {
    let state_path = state_dir().join("state.json");
    let socket = socket_path().to_string_lossy().into_owned();
    let mut state = match state::load(&state_path, &socket)? {
        Some(state) => state,
        None => {
            let mut state = State::new(socket);
            // Only migrate the default session: the old file was global and
            // cannot establish ownership in arbitrary named sessions.
            let legacy_path = state_root().join("herdr-autoname/state.json");
            let legacy = if session_dir() == resolve_socket(Some("default"))?.parent().unwrap() {
                match fs::read(&legacy_path) {
                    Ok(bytes) => serde_json::from_slice::<LegacyState>(&bytes)
                        .with_context(|| format!("decode legacy {}", legacy_path.display()))?,
                    Err(error) if error.kind() == std::io::ErrorKind::NotFound => {
                        LegacyState::default()
                    }
                    Err(error) => return Err(error.into()),
                }
            } else {
                LegacyState::default()
            };
            for tab in &snapshot.tabs {
                state.tabs.insert(
                    tab.tab_id.clone(),
                    initial_tab_state(tab, legacy.tabs.get(&tab.tab_id).map(String::as_str)),
                );
            }
            state::save(&state_path, &state)?;
            state
        }
    };
    let mut seen = HashSet::new();
    let panes_by_tab = panes_by_tab(&snapshot.panes);
    let layouts: HashMap<&str, &str> = snapshot
        .layouts
        .iter()
        .filter_map(|layout| Some((layout.tab_id.as_str(), layout.focused_pane_id.as_deref()?)))
        .collect();
    let mut positions: HashMap<&str, usize> = HashMap::new();

    for tab in &mut snapshot.tabs {
        seen.insert(tab.tab_id.clone());
        let position = positions.entry(&tab.workspace_id).or_default();
        *position += 1;
        if only.is_some_and(|targets| !targets.contains(&tab.tab_id)) {
            continue;
        }
        foreground_tabs.remove(&tab.tab_id);

        let current_base = strip_numeric_prefix(&tab.label);
        let owner = state
            .tabs
            .entry(tab.tab_id.clone())
            .or_insert_with(|| initial_tab_state(tab, None));
        owner.observe(&tab.label);
        let forced = force_tab == Some(tab.tab_id.as_str());
        if forced {
            owner.automatic = true;
            owner.last_label = tab.label.clone();
        }
        let eligible = owner.automatic;

        let computed = if eligible {
            relevant_pane(
                panes_by_tab
                    .get(tab.tab_id.as_str())
                    .map(Vec::as_slice)
                    .unwrap_or_default(),
                layouts.get(tab.tab_id.as_str()).copied(),
            )
            .map(|pane| {
                if pane
                    .agent
                    .as_deref()
                    .and_then(|agent| meaningful_agent_title(pane, agent))
                    .is_none()
                {
                    foreground_tabs.insert(tab.tab_id.clone());
                }
                tab_name(pane)
            })
            .transpose()?
            .flatten()
        } else {
            None
        };

        let base = computed.as_deref().unwrap_or(current_base);
        if eligible && computed.is_none() && is_placeholder(current_base) {
            continue;
        }
        let desired = indexed_tab_label(*position, base);
        if desired != tab.label {
            // Recheck before writing: a manual rename since the snapshot must
            // not be overwritten. Herdr has no atomic compare-and-rename API.
            let current = request("tab.get", json!({"tab_id": tab.tab_id}))?;
            if current.pointer("/tab/label").and_then(Value::as_str) != Some(&tab.label) {
                continue;
            }
            owner.pending_label = Some(desired.clone());
            state::save(&state_path, &state)?;
            request(
                "tab.rename",
                json!({"tab_id": tab.tab_id, "label": desired}),
            )?;
            let owner = state.tabs.get_mut(&tab.tab_id).expect("known tab");
            owner.last_label = desired;
            tab.label = owner.last_label.clone();
            owner.pending_label = None;
            state::save(&state_path, &state)?;
        }
    }

    state.tabs.retain(|tab_id, _| seen.contains(tab_id));
    // Avoid disk writes on idle polls.
    if state::load(&state_path, &state.socket)?.as_ref() != Some(&state) {
        state::save(&state_path, &state)?;
    }
    Ok(())
}

fn initial_tab_state(tab: &Tab, legacy_base: Option<&str>) -> TabState {
    let base = strip_numeric_prefix(&tab.label);
    TabState {
        automatic: is_placeholder(base) || legacy_base == Some(base),
        last_label: tab.label.clone(),
        pending_label: None,
    }
}

fn panes_by_tab(panes: &[Pane]) -> HashMap<&str, Vec<&Pane>> {
    let mut result: HashMap<&str, Vec<&Pane>> = HashMap::new();
    for pane in panes {
        result.entry(&pane.tab_id).or_default().push(pane);
    }
    result
}

fn relevant_pane<'a>(panes: &[&'a Pane], focused_pane_id: Option<&str>) -> Option<&'a Pane> {
    let focused =
        focused_pane_id.and_then(|id| panes.iter().find(|pane| pane.pane_id == id).copied());
    if let Some(pane) = focused
        && pane.agent.is_some()
    {
        return Some(pane);
    }
    if let Some(pane) = panes
        .iter()
        .find(|pane| {
            pane.agent.is_some()
                && !matches!(
                    pane.agent_status.as_deref(),
                    None | Some("idle" | "done" | "unknown")
                )
        })
        .copied()
    {
        return Some(pane);
    }
    focused.or_else(|| (panes.len() == 1).then(|| panes[0]))
}

fn tab_name(pane: &Pane) -> Result<Option<String>> {
    if let Some(agent) = pane.agent.as_deref()
        && let Some(title) = meaningful_agent_title(pane, agent)
    {
        return Ok(Some(title));
    }
    let Some(mut program) = pane_program(&pane.pane_id)? else {
        return Ok(None);
    };
    if is_wrapper(&program)
        && let Some(agent) = pane.agent.as_deref()
    {
        program = agent.to_string();
    }
    if is_shell_or_ignored(&program) {
        program = shell_name();
    }
    Ok(Some(truncate(&program, MAX_NAME_LEN, false)))
}

fn pane_program(pane_id: &str) -> Result<Option<String>> {
    if let Some(program) = PROGRAMS.with(|cache| {
        cache
            .borrow()
            .get(pane_id)
            .filter(|(time, _)| time.elapsed() < FOREGROUND_INTERVAL)
            .map(|(_, program)| program.clone())
    }) {
        return Ok(program);
    }
    let program = read_pane_program(pane_id)?;
    PROGRAMS.with(|cache| {
        cache
            .borrow_mut()
            .insert(pane_id.into(), (Instant::now(), program.clone()))
    });
    Ok(program)
}

fn read_pane_program(pane_id: &str) -> Result<Option<String>> {
    let value = request("pane.process_info", json!({"pane_id": pane_id}))?;
    let info: ProcessInfo = serde_json::from_value(
        value
            .get("process_info")
            .cloned()
            .context("missing process_info")?,
    )
    .context("decode foreground processes")?;
    let process = match info.foreground_process_group_id {
        Some(group) => info
            .foreground_processes
            .iter()
            .find(|process| process.pid == group),
        None if info.foreground_processes.len() == 1 => info.foreground_processes.first(),
        None => None,
    };
    let Some(process) = process else {
        return Ok(None);
    };
    let argv0 = process
        .argv0
        .as_deref()
        .or_else(|| process.argv.first().map(String::as_str))
        .or(process.name.as_deref());
    let Some(argv0) = argv0 else {
        return Ok(None);
    };
    let name = argv0
        .rsplit('/')
        .next()
        .unwrap_or(argv0)
        .trim_start_matches('-');
    Ok((!name.is_empty()).then(|| name.to_string()))
}

fn meaningful_agent_title(pane: &Pane, agent: &str) -> Option<String> {
    let mut title = pane
        .terminal_title_stripped
        .as_deref()
        .or(pane.terminal_title.as_deref())?
        .to_string();
    title = normalize_whitespace(&title);
    if matches!(agent, "pi" | "omp") {
        title = title.strip_prefix('π').unwrap_or(&title).to_string();
    }
    title = title
        .trim_start_matches(|character: char| !character.is_alphanumeric())
        .trim()
        .to_string();
    if title.is_empty() || title.chars().all(|character| character.is_ascii_digit()) {
        return None;
    }

    let lower = title.to_ascii_lowercase();
    let agent_lower = agent.to_ascii_lowercase();
    let ignored = [
        "claude code",
        "codex cli",
        "gemini cli",
        "opencode",
        "amp code",
        "cursor agent",
        "new session",
        "untitled",
    ];
    if lower == agent_lower
        || lower == format!("{agent_lower} code")
        || ignored.contains(&lower.as_str())
    {
        return None;
    }

    let directory = pane
        .foreground_cwd
        .as_deref()
        .or(pane.cwd.as_deref())
        .and_then(|cwd| Path::new(cwd).file_name())
        .and_then(|name| name.to_str())
        .unwrap_or("")
        .to_ascii_lowercase();
    let tail = lower.trim_end_matches('/').rsplit('/').next().unwrap_or("");
    if !directory.is_empty()
        && (lower == directory || (!lower.contains(char::is_whitespace) && tail == directory))
    {
        return None;
    }
    Some(truncate(&title, MAX_TITLE_LEN, true))
}

fn normalize_whitespace(value: &str) -> String {
    value
        .chars()
        .map(|character| {
            if character.is_control() {
                ' '
            } else {
                character
            }
        })
        .collect::<String>()
        .split_whitespace()
        .collect::<Vec<_>>()
        .join(" ")
}

fn truncate(value: &str, limit: usize, at_word: bool) -> String {
    let mut result: String = value.chars().take(limit).collect();
    if value.chars().count() <= limit || !at_word {
        return result;
    }
    if let Some(boundary) = result.rfind(' ')
        && result[..boundary].chars().count() >= limit / 2
    {
        result.truncate(boundary);
    }
    result
}

fn shell_name() -> String {
    std::env::var("SHELL")
        .ok()
        .and_then(|shell| shell.rsplit('/').next().map(str::to_string))
        .filter(|shell| !shell.is_empty())
        .unwrap_or_else(|| "zsh".into())
}

fn is_shell_or_ignored(program: &str) -> bool {
    const NAMES: &[&str] = &[
        "zsh", "bash", "sh", "fish", "dash", "ksh", "ls", "eza", "ll", "la", "cd", "z", "zoxide",
        "cat", "bat", "less", "more", "echo", "pwd", "clear", "which", "man", "head", "tail", "wc",
        "cp", "mv", "rm", "mkdir", "touch", "fzf", "sudo", "doas",
    ];
    NAMES.contains(&program) || program == shell_name()
}

fn is_wrapper(program: &str) -> bool {
    const WRAPPERS: &[&str] = &[
        "node", "bun", "deno", "npx", "bunx", "npm", "pnpm", "yarn", "python", "python3", "uv",
        "uvx", "pipx", "ruby",
    ];
    WRAPPERS.contains(&program)
}

fn indexed_tab_label(position: usize, base: &str) -> String {
    if position <= 9 {
        if base.is_empty() {
            format!("[{position}]")
        } else {
            format!("[{position}] {base}")
        }
    } else {
        base.to_string()
    }
}

fn numeric_prefix(label: &str) -> Option<(&str, &str)> {
    let rest = label.strip_prefix('[')?;
    let close = rest.find(']')?;
    let number = &rest[..close];
    if number.is_empty() || !number.chars().all(|character| character.is_ascii_digit()) {
        return None;
    }
    let suffix = &rest[close + 1..];
    if suffix.is_empty() {
        Some((number, ""))
    } else {
        suffix.strip_prefix(' ').map(|base| (number, base))
    }
}

fn strip_numeric_prefix(label: &str) -> &str {
    numeric_prefix(label).map_or(label, |(_, base)| base)
}

fn is_placeholder(label: &str) -> bool {
    label.is_empty() || label.chars().all(|character| character.is_ascii_digit())
}

fn reset_target(snapshot: &Snapshot) -> Option<String> {
    std::env::var("HERDR_TAB_ID")
        .ok()
        .or_else(|| {
            let context = std::env::var("HERDR_PLUGIN_CONTEXT_JSON").ok()?;
            let value: Value = serde_json::from_str(&context).ok()?;
            value
                .pointer("/tab/tab_id")
                .or_else(|| value.pointer("/tab/id"))
                .or_else(|| value.get("tab_id"))?
                .as_str()
                .map(str::to_string)
        })
        .or_else(|| {
            // Snapshot tabs do not need to expose focused for normal operation;
            // the action environment is the authoritative target. Keep a safe
            // fallback for CLI invocation by asking Herdr directly.
            let value = request("tab.list", json!({})).ok()?;
            value
                .get("tabs")?
                .as_array()?
                .iter()
                .find(|tab| tab.get("focused").and_then(Value::as_bool) == Some(true))?
                .get("tab_id")?
                .as_str()
                .map(str::to_string)
        })
        .filter(|tab_id| snapshot.tabs.iter().any(|tab| &tab.tab_id == tab_id))
}

#[cfg(test)]
mod tests {
    use super::*;

    fn workspace(id: &str, repo: Option<(&str, bool)>) -> Workspace {
        Workspace {
            workspace_id: id.into(),
            worktree: repo.map(|(repo_key, linked)| Worktree {
                repo_key: repo_key.into(),
                is_linked_worktree: linked,
            }),
            ..Workspace::default()
        }
    }

    #[test]
    fn numeric_prefix_is_strict() {
        assert_eq!(numeric_prefix("[1] nvim"), Some(("1", "nvim")));
        assert_eq!(numeric_prefix("[12]"), Some(("12", "")));
        assert_eq!(numeric_prefix("[wip] nvim"), None);
        assert_eq!(numeric_prefix("[1]nvim"), None);
    }

    #[test]
    fn tab_labels_keep_bracketed_indexes() {
        assert_eq!(indexed_tab_label(1, "nvim"), "[1] nvim");
        assert_eq!(indexed_tab_label(9, "zsh"), "[9] zsh");
        assert_eq!(indexed_tab_label(10, "notes"), "notes");
    }

    #[test]
    fn relevant_pane_prefers_agents_at_work() {
        let shell = Pane {
            pane_id: "p1".into(),
            ..Pane::default()
        };
        let agent = Pane {
            pane_id: "p2".into(),
            agent: Some("claude".into()),
            agent_status: Some("working".into()),
            ..Pane::default()
        };
        assert_eq!(
            relevant_pane(&[&shell, &agent], Some("p1")).map(|pane| pane.pane_id.as_str()),
            Some("p2")
        );
    }

    #[test]
    fn empty_layout_does_not_panic() {
        assert!(relevant_pane(&[], None).is_none());
        assert!(relevant_pane(&[], Some("closed-pane")).is_none());
    }

    #[test]
    fn migration_does_not_guess_from_index_prefix() {
        let tab = Tab {
            tab_id: "t1".into(),
            label: "[1] Custom".into(),
            ..Tab::default()
        };
        assert!(!initial_tab_state(&tab, None).automatic);
        assert!(initial_tab_state(&tab, Some("Custom")).automatic);
        assert!(!initial_tab_state(&tab, Some("Old")).automatic);
    }

    #[test]
    fn index_updates_do_not_invalidate_title_snapshot() {
        let snapshot = Snapshot {
            panes: vec![Pane {
                pane_id: "p1".into(),
                tab_id: "t1".into(),
                terminal_title_stripped: Some("Task".into()),
                ..Pane::default()
            }],
            ..Snapshot::default()
        };
        let event = json!({"event": "pane.updated", "data": {"pane": {
            "pane_id": "p1", "tab_id": "t1", "terminal_title_stripped": "Task",
            "revision": 123, "tokens": {"autoname_index": "2"}, "scroll": {}
        }}});
        assert!(!relevant_event(&event, &snapshot));
        let mut changed = event;
        changed["data"]["pane"]["terminal_title_stripped"] = json!("New task");
        assert!(relevant_event(&changed, &snapshot));
    }

    #[test]
    fn incomplete_snapshot_is_not_an_empty_session() {
        assert!(serde_json::from_value::<Snapshot>(json!({"tabs": []})).is_err());
    }

    #[test]
    fn session_names_match_herdr_validation() {
        assert!(
            resolve_socket(Some("work.project"))
                .unwrap()
                .ends_with("sessions/work.project/herdr.sock")
        );
        for invalid in ["", ".", "..", "../other", "two words"] {
            assert!(resolve_socket(Some(invalid)).is_err());
        }
        assert!(resolve_socket(Some(&"a".repeat(65))).is_err());
    }

    #[test]
    fn main_checkout_heads_visible_workspace_group() {
        let snapshot = Snapshot {
            workspaces: vec![
                workspace("linked", Some(("repo", true))),
                workspace("main", Some(("repo", false))),
                workspace("plain", None),
            ],
            ..Snapshot::default()
        };
        let positions = visible_workspace_positions(&snapshot);
        assert_eq!(positions["main"], 1);
        assert_eq!(positions["linked"], 2);
        assert_eq!(positions["plain"], 3);
    }

    #[test]
    fn normalizes_and_truncates_titles() {
        assert_eq!(
            normalize_whitespace("  Fix\t the\n parser "),
            "Fix the parser"
        );
        assert_eq!(
            truncate("Investigate parser behavior", 20, true),
            "Investigate parser"
        );
    }
}
