use anyhow::{Context, Result, bail};
use serde::{Deserialize, Serialize};
use std::collections::BTreeMap;
use std::fs;
use std::io::Write;
use std::path::Path;

#[derive(Debug, Clone, Default, Serialize, Deserialize, PartialEq, Eq)]
pub struct TabState {
    pub automatic: bool,
    pub last_label: String,
    /// Write-ahead intent lets a successful rename survive a process crash
    /// between the API response and the final state write.
    pub pending_label: Option<String>,
}

impl TabState {
    pub fn observe(&mut self, label: &str) {
        if self.pending_label.as_deref() == Some(label) {
            self.last_label = label.into();
        } else if self.last_label != label {
            self.automatic = false;
            self.last_label = label.into();
        }
        self.pending_label = None;
    }
}

#[derive(Debug, Serialize, Deserialize, PartialEq, Eq)]
pub struct State {
    pub version: u32,
    pub socket: String,
    pub tabs: BTreeMap<String, TabState>,
}

impl State {
    pub fn new(socket: String) -> Self {
        Self {
            version: 2,
            socket,
            tabs: BTreeMap::new(),
        }
    }
}

pub fn load(path: &Path, socket: &str) -> Result<Option<State>> {
    let bytes = match fs::read(path) {
        Ok(bytes) => bytes,
        Err(error) if error.kind() == std::io::ErrorKind::NotFound => return Ok(None),
        Err(error) => return Err(error).with_context(|| format!("read {}", path.display())),
    };
    let state: State = serde_json::from_slice(&bytes)
        .with_context(|| format!("decode {}; refusing to discard ownership", path.display()))?;
    if state.version != 2 || state.socket != socket {
        bail!(
            "unsupported state version or socket identity in {}",
            path.display()
        );
    }
    Ok(Some(state))
}

pub fn save(path: &Path, state: &State) -> Result<()> {
    let temp = path.with_extension(format!("tmp.{}", std::process::id()));
    let mut file = fs::File::create(&temp)?;
    file.write_all(&serde_json::to_vec_pretty(state)?)?;
    file.sync_all()?;
    fs::rename(&temp, path).with_context(|| format!("replace {}", path.display()))?;
    fs::File::open(path.parent().context("state has no parent")?)?.sync_all()?;
    Ok(())
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn own_rename_survives_crash() {
        let mut state = TabState {
            automatic: true,
            last_label: "[1] old".into(),
            pending_label: Some("[2] new".into()),
        };
        state.observe("[2] new");
        assert!(state.automatic);
        assert_eq!(state.last_label, "[2] new");
        assert_eq!(state.pending_label, None);
    }

    #[test]
    fn failed_rename_does_not_lose_ownership() {
        let mut state = TabState {
            automatic: true,
            last_label: "[1] old".into(),
            pending_label: Some("[1] new".into()),
        };
        state.observe("[1] old");
        assert!(state.automatic);
        assert_eq!(state.last_label, "[1] old");
    }

    #[test]
    fn manual_placeholder_is_still_manual() {
        let mut state = TabState {
            automatic: true,
            last_label: "[1] old".into(),
            pending_label: None,
        };
        state.observe("2");
        assert!(!state.automatic);
    }
}
