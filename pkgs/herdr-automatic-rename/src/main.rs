//! Focused Herdr navigation labels for Ben's configuration.
//!
//! - Workspaces and agents publish a bare 1-9 jump-key number as display-only
//!   metadata (`$automatic_rename_index`).
//! - Tabs are named after the relevant pane's agent task or foreground program
//!   and retain an `[N]` jump-key prefix.
//! - A tab renamed by hand opts out of automatic naming, while numbering still
//!   follows tab order.
//!
//! Herdr 0.8.2 is the only supported baseline. There is deliberately no shell
//! hook: foreground names reconcile on Herdr events rather than every command.

use anyhow::{Context, Result, bail};
use fs2::FileExt;
use serde::{Deserialize, Serialize};
use serde_json::Value;
use std::collections::{BTreeMap, HashMap, HashSet};
use std::fs::{self, OpenOptions};
use std::path::{Path, PathBuf};
use std::process::Command;

const INDEX_TOKEN: &str = "automatic_rename_index";
const METADATA_SOURCE: &str = "herdr-automatic-rename";
const MAX_NAME_LEN: usize = 20;
const MAX_TITLE_LEN: usize = 28;

#[derive(Debug, Default, Deserialize)]
struct SnapshotEnvelope {
    result: SnapshotResult,
}

#[derive(Debug, Default, Deserialize)]
struct SnapshotResult {
    snapshot: Snapshot,
}

#[derive(Debug, Default, Deserialize)]
struct Snapshot {
    #[serde(default)]
    workspaces: Vec<Workspace>,
    #[serde(default)]
    tabs: Vec<Tab>,
    #[serde(default)]
    panes: Vec<Pane>,
    #[serde(default)]
    agents: Vec<Agent>,
    #[serde(default)]
    layouts: Vec<Layout>,
}

#[derive(Debug, Default, Deserialize)]
struct Workspace {
    workspace_id: String,
    #[serde(default)]
    label: String,
    #[serde(default)]
    focused: bool,
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

#[derive(Debug, Default, Deserialize)]
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

#[derive(Debug, Default, Serialize, Deserialize, PartialEq, Eq)]
struct State {
    #[serde(default)]
    tabs: BTreeMap<String, String>,
}

#[derive(Debug, Deserialize)]
struct LegacyTabState {
    #[serde(default)]
    auto: String,
    #[serde(default)]
    enabled: bool,
}

#[derive(Debug, Default, Deserialize)]
struct SessionState {
    #[serde(default)]
    collapsed_space_keys: Vec<String>,
}

#[derive(Debug, Default, Deserialize)]
struct ProcessInfoEnvelope {
    result: ProcessInfoResult,
}

#[derive(Debug, Default, Deserialize)]
struct ProcessInfoResult {
    process_info: ProcessInfo,
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
    let mode = std::env::args().nth(1).unwrap_or_else(|| "event".into());
    let state_dir = state_dir();
    fs::create_dir_all(&state_dir).with_context(|| format!("create {}", state_dir.display()))?;
    let lock_path = state_dir.join("lock");
    let lock = OpenOptions::new()
        .create(true)
        .truncate(false)
        .read(true)
        .write(true)
        .open(&lock_path)
        .with_context(|| format!("open {}", lock_path.display()))?;
    lock.lock_exclusive().context("lock plugin state")?;

    let snapshot = read_snapshot()?;
    let force_tab = if mode == "reset" {
        reset_target(&snapshot)
    } else {
        None
    };
    reconcile(&snapshot, force_tab.as_deref())?;

    FileExt::unlock(&lock).context("unlock plugin state")?;
    Ok(())
}

fn herdr_bin() -> String {
    std::env::var("HERDR_BIN_PATH").unwrap_or_else(|_| "herdr".into())
}

fn herdr_json(args: &[&str]) -> Result<Value> {
    let output = Command::new(herdr_bin())
        .args(args)
        .output()
        .with_context(|| format!("run herdr {}", args.join(" ")))?;
    if !output.status.success() {
        bail!(
            "herdr {} failed: {}",
            args.join(" "),
            String::from_utf8_lossy(&output.stderr).trim()
        );
    }
    serde_json::from_slice(&output.stdout)
        .with_context(|| format!("parse herdr {} response", args.join(" ")))
}

fn herdr_mutate(args: &[&str]) -> bool {
    Command::new(herdr_bin())
        .args(args)
        .status()
        .is_ok_and(|status| status.success())
}

fn read_snapshot() -> Result<Snapshot> {
    let value = herdr_json(&["api", "snapshot"])?;
    let envelope: SnapshotEnvelope =
        serde_json::from_value(value).context("decode Herdr snapshot")?;
    Ok(envelope.result.snapshot)
}

fn state_root() -> PathBuf {
    std::env::var_os("XDG_STATE_HOME")
        .map(PathBuf::from)
        .unwrap_or_else(|| home_dir().join(".local/state"))
}

fn state_dir() -> PathBuf {
    state_root().join("herdr-automatic-rename-rs")
}

fn home_dir() -> PathBuf {
    std::env::var_os("HOME").map_or_else(PathBuf::new, PathBuf::from)
}

fn session_dir() -> PathBuf {
    std::env::var_os("HERDR_SOCKET_PATH")
        .and_then(|path| PathBuf::from(path).parent().map(Path::to_path_buf))
        .unwrap_or_else(|| home_dir().join(".config/herdr"))
}

fn load_state(path: &Path) -> State {
    if let Some(state) = fs::read(path)
        .ok()
        .and_then(|bytes| serde_json::from_slice(&bytes).ok())
    {
        return state;
    }

    // One-time migration from the shell plugin's {tab: {auto, enabled}} file.
    // Keeping its claims prevents every currently auto-named tab from looking
    // like a manual rename when the Nix-built plugin first takes over.
    let legacy_path = state_root().join("herdr-automatic-rename/state.json");
    let legacy: BTreeMap<String, LegacyTabState> = fs::read(legacy_path)
        .ok()
        .and_then(|bytes| serde_json::from_slice(&bytes).ok())
        .unwrap_or_default();
    State {
        tabs: legacy
            .into_iter()
            .filter(|(_, entry)| entry.enabled)
            .map(|(tab_id, entry)| (tab_id, entry.auto))
            .collect(),
    }
}

fn save_state(path: &Path, state: &State) -> Result<()> {
    let bytes = serde_json::to_vec_pretty(state)?;
    let temp = path.with_extension(format!("tmp.{}", std::process::id()));
    fs::write(&temp, bytes).with_context(|| format!("write {}", temp.display()))?;
    fs::rename(&temp, path).with_context(|| format!("replace {}", path.display()))
}

fn reconcile(snapshot: &Snapshot, force_tab: Option<&str>) -> Result<()> {
    reconcile_workspaces(snapshot);
    reconcile_agents(snapshot);
    reconcile_tabs(snapshot, force_tab)
}

fn reconcile_workspaces(snapshot: &Snapshot) {
    let positions = visible_workspace_positions(snapshot);
    for workspace in &snapshot.workspaces {
        let current = workspace.tokens.get(INDEX_TOKEN).map(String::as_str);
        // Releases before the metadata design embedded `[N]` in custom_name.
        // Suppress a second number until that legacy workspace is recreated.
        let desired = if numeric_prefix(&workspace.label).is_some() {
            None
        } else {
            positions
                .get(&workspace.workspace_id)
                .copied()
                .filter(|position| (1..=9).contains(position))
                .map(|position| position.to_string())
        };
        report_workspace_token(&workspace.workspace_id, current, desired.as_deref());
    }
}

fn visible_workspace_positions(snapshot: &Snapshot) -> HashMap<String, usize> {
    let collapsed: HashSet<String> = fs::read(session_dir().join("session.json"))
        .ok()
        .and_then(|bytes| serde_json::from_slice::<SessionState>(&bytes).ok())
        .unwrap_or_default()
        .collapsed_space_keys
        .into_iter()
        .collect();
    visible_workspace_positions_with_collapsed(snapshot, &collapsed)
}

fn visible_workspace_positions_with_collapsed(
    snapshot: &Snapshot,
    collapsed: &HashSet<String>,
) -> HashMap<String, usize> {
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

    let focused = snapshot
        .workspaces
        .iter()
        .position(|workspace| workspace.focused);
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
        if collapsed.contains(&worktree.repo_key) {
            if let Some(active) = focused
                && active != members[0]
                && members.contains(&active)
            {
                order.push(active);
            }
        } else {
            order.extend(members.iter().skip(1).copied());
        }
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

fn reconcile_agents(snapshot: &Snapshot) {
    let grouped = agent_panel_sort() != "priority";
    for (index, agent) in snapshot.agents.iter().enumerate() {
        let current = agent.tokens.get(INDEX_TOKEN).map(String::as_str);
        let desired = grouped
            .then_some(index + 1)
            .filter(|position| *position <= 9)
            .map(|position| position.to_string());
        report_pane_token(&agent.pane_id, current, desired.as_deref());
    }
}

fn agent_panel_sort() -> String {
    let config = fs::read_to_string(session_dir().join("config.toml")).unwrap_or_default();
    config
        .lines()
        .filter_map(|line| line.trim().split_once('='))
        .find_map(|(key, value)| {
            (key.trim() == "agent_panel_sort")
                .then(|| value.trim().trim_matches(['\'', '"']).to_string())
        })
        .unwrap_or_else(|| "spaces".into())
}

fn report_workspace_token(workspace_id: &str, current: Option<&str>, desired: Option<&str>) {
    if current == desired {
        return;
    }
    match desired {
        Some(value) => {
            let token = format!("{INDEX_TOKEN}={value}");
            herdr_mutate(&[
                "workspace",
                "report-metadata",
                workspace_id,
                "--source",
                METADATA_SOURCE,
                "--token",
                &token,
            ]);
        }
        None if current.is_some() => {
            herdr_mutate(&[
                "workspace",
                "report-metadata",
                workspace_id,
                "--source",
                METADATA_SOURCE,
                "--clear-token",
                INDEX_TOKEN,
            ]);
        }
        None => {}
    }
}

fn report_pane_token(pane_id: &str, current: Option<&str>, desired: Option<&str>) {
    if current == desired {
        return;
    }
    match desired {
        Some(value) => {
            let token = format!("{INDEX_TOKEN}={value}");
            herdr_mutate(&[
                "pane",
                "report-metadata",
                pane_id,
                "--source",
                METADATA_SOURCE,
                "--token",
                &token,
            ]);
        }
        None if current.is_some() => {
            herdr_mutate(&[
                "pane",
                "report-metadata",
                pane_id,
                "--source",
                METADATA_SOURCE,
                "--clear-token",
                INDEX_TOKEN,
            ]);
        }
        None => {}
    }
}

fn reconcile_tabs(snapshot: &Snapshot, force_tab: Option<&str>) -> Result<()> {
    let state_path = state_dir().join("state.json");
    let previous_state = load_state(&state_path);
    let mut state = previous_state.tabs.clone();
    let mut seen = HashSet::new();
    let panes_by_tab = panes_by_tab(snapshot);
    let layouts: HashMap<&str, &str> = snapshot
        .layouts
        .iter()
        .filter_map(|layout| Some((layout.tab_id.as_str(), layout.focused_pane_id.as_deref()?)))
        .collect();
    let mut positions: HashMap<&str, usize> = HashMap::new();

    for tab in &snapshot.tabs {
        seen.insert(tab.tab_id.clone());
        let position = positions.entry(&tab.workspace_id).or_default();
        *position += 1;

        let current_base = strip_numeric_prefix(&tab.label);
        let previous = state.get(&tab.tab_id).cloned();
        let forced = force_tab == Some(tab.tab_id.as_str());
        let eligible =
            forced || is_placeholder(current_base) || previous.as_deref() == Some(current_base);

        let computed = if eligible {
            relevant_pane(
                panes_by_tab
                    .get(tab.tab_id.as_str())
                    .map(Vec::as_slice)
                    .unwrap_or_default(),
                layouts.get(tab.tab_id.as_str()).copied(),
            )
            .and_then(tab_name)
        } else {
            None
        };

        if !eligible {
            state.remove(&tab.tab_id);
        }

        let base = match (eligible, computed.as_deref(), previous.as_deref()) {
            (true, Some(name), _) => name,
            (true, None, Some(last)) if last == current_base => current_base,
            (true, None, _) if is_placeholder(current_base) => continue,
            _ => current_base,
        };
        let desired = indexed_tab_label(*position, base);
        let landed =
            desired == tab.label || herdr_mutate(&["tab", "rename", &tab.tab_id, &desired]);
        if landed
            && eligible
            && let Some(name) = computed
        {
            state.insert(tab.tab_id.clone(), name);
        }
    }

    state.retain(|tab_id, _| seen.contains(tab_id));
    let next = State { tabs: state };
    if next != previous_state || !state_path.exists() {
        save_state(&state_path, &next)?;
    }
    Ok(())
}

fn panes_by_tab(snapshot: &Snapshot) -> HashMap<&str, Vec<&Pane>> {
    let mut result: HashMap<&str, Vec<&Pane>> = HashMap::new();
    for pane in &snapshot.panes {
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
    focused.or_else(|| (panes.len() == 1).then_some(panes[0]))
}

fn tab_name(pane: &Pane) -> Option<String> {
    if let Some(agent) = pane.agent.as_deref()
        && let Some(title) = meaningful_agent_title(pane, agent)
    {
        return Some(title);
    }
    let mut program = pane_program(&pane.pane_id)?;
    if is_wrapper(&program)
        && let Some(agent) = pane.agent.as_deref()
    {
        program = agent.to_string();
    }
    if is_shell_or_ignored(&program) {
        program = shell_name();
    }
    Some(truncate(&program, MAX_NAME_LEN, false))
}

fn pane_program(pane_id: &str) -> Option<String> {
    let value = herdr_json(&["pane", "process-info", "--pane", pane_id]).ok()?;
    let envelope: ProcessInfoEnvelope = serde_json::from_value(value).ok()?;
    let info = envelope.result.process_info;
    let process = match info.foreground_process_group_id {
        Some(group) => info
            .foreground_processes
            .iter()
            .find(|process| process.pid == group),
        None if info.foreground_processes.len() == 1 => info.foreground_processes.first(),
        None => None,
    }?;
    let argv0 = process
        .argv0
        .as_deref()
        .or_else(|| process.argv.first().map(String::as_str))
        .or(process.name.as_deref())?;
    let name = argv0
        .rsplit('/')
        .next()
        .unwrap_or(argv0)
        .trim_start_matches('-');
    (!name.is_empty()).then(|| name.to_string())
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
            let value = herdr_json(&["tab", "list"]).ok()?;
            value
                .pointer("/result/tabs")?
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

    fn workspace(id: &str, focused: bool, repo: Option<(&str, bool)>) -> Workspace {
        Workspace {
            workspace_id: id.into(),
            focused,
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
    fn main_checkout_heads_visible_workspace_group() {
        let snapshot = Snapshot {
            workspaces: vec![
                workspace("linked", false, Some(("repo", true))),
                workspace("main", true, Some(("repo", false))),
                workspace("plain", false, None),
            ],
            ..Snapshot::default()
        };
        let positions = visible_workspace_positions_with_collapsed(&snapshot, &HashSet::new());
        assert_eq!(positions["main"], 1);
        assert_eq!(positions["linked"], 2);
        assert_eq!(positions["plain"], 3);
    }

    #[test]
    fn collapsed_group_hides_unfocused_members() {
        let snapshot = Snapshot {
            workspaces: vec![
                workspace("main", true, Some(("repo", false))),
                workspace("linked", false, Some(("repo", true))),
                workspace("plain", false, None),
            ],
            ..Snapshot::default()
        };
        let positions = visible_workspace_positions_with_collapsed(
            &snapshot,
            &HashSet::from(["repo".to_string()]),
        );
        assert!(!positions.contains_key("linked"));
        assert_eq!(positions["plain"], 2);
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
