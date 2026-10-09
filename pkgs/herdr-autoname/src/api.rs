//! Bounded newline-delimited JSON transport for Herdr's public Unix socket API.
use anyhow::{Context, Result, bail};
use serde_json::{Value, json};
use std::io::{BufRead, BufReader, Read, Write};
use std::os::unix::net::UnixStream;
use std::path::Path;
use std::time::Duration;

const MAX_FRAME: usize = 16 * 1024 * 1024;

pub fn connect(path: &Path) -> Result<UnixStream> {
    let stream =
        UnixStream::connect(path).with_context(|| format!("connect {}", path.display()))?;
    stream.set_read_timeout(Some(Duration::from_secs(5)))?;
    stream.set_write_timeout(Some(Duration::from_secs(5)))?;
    Ok(stream)
}

pub fn send(stream: &mut UnixStream, method: &str, params: Value) -> Result<()> {
    let request = json!({"id": "autoname", "method": method, "params": params});
    let mut bytes = serde_json::to_vec(&request)?;
    bytes.push(b'\n');
    stream.write_all(&bytes).context("send Herdr request")
}

pub fn result(response: Value) -> Result<Value> {
    if let Some(error) = response.get("error") {
        bail!("Herdr API error: {error}");
    }
    response
        .get("result")
        .cloned()
        .context("Herdr response has no result")
}

pub fn request(path: &Path, method: &str, params: Value) -> Result<Value> {
    let mut stream = connect(path)?;
    send(&mut stream, method, params)?;
    let mut bytes = Vec::new();
    BufReader::new(stream)
        .take((MAX_FRAME + 1) as u64)
        .read_until(b'\n', &mut bytes)?;
    if bytes.len() > MAX_FRAME || bytes.last() != Some(&b'\n') {
        bail!("incomplete or oversized Herdr response");
    }
    result(serde_json::from_slice(&bytes)?)
}

/// Preserve partial frames across read timeouts; read_line would lose them.
pub struct Events {
    stream: UnixStream,
    pending: Vec<u8>,
}

impl Events {
    pub fn subscribe(path: &Path) -> Result<Self> {
        let mut stream = connect(path)?;
        let names = [
            "workspace.created",
            "workspace.closed",
            "workspace.updated",
            "workspace.renamed",
            "workspace.moved",
            "workspace.reordered",
            "workspace.focused",
            "tab.created",
            "tab.closed",
            "tab.renamed",
            "tab.moved",
            "tab.focused",
            "pane.created",
            "pane.closed",
            "pane.updated",
            "pane.focused",
            "pane.moved",
            "pane.exited",
            "pane.agent_detected",
            "layout.updated",
        ];
        send(
            &mut stream,
            "events.subscribe",
            json!({
                "subscriptions": names.map(|name| json!({"type": name}))
            }),
        )?;
        let mut events = Self {
            stream,
            pending: Vec::new(),
        };
        let ack = events
            .next(Some(Duration::from_secs(5)))?
            .context("subscription closed before acknowledgement")?;
        let ack = result(ack)?;
        if ack.get("type").and_then(Value::as_str) != Some("subscription_started") {
            bail!("unexpected subscription acknowledgement: {ack}");
        }
        Ok(events)
    }

    pub fn next(&mut self, timeout: Option<Duration>) -> Result<Option<Value>> {
        self.stream
            .set_read_timeout(timeout.map(|duration| duration.max(Duration::from_millis(1))))?;
        loop {
            if let Some(end) = self.pending.iter().position(|byte| *byte == b'\n') {
                let frame: Vec<_> = self.pending.drain(..=end).collect();
                let value: Value = serde_json::from_slice(&frame)?;
                if let Some(error) = value.get("error") {
                    bail!("Herdr subscription error: {error}");
                }
                return Ok(Some(value));
            }
            let mut bytes = [0; 8192];
            match self.stream.read(&mut bytes) {
                Ok(0) => {
                    return Err(std::io::Error::new(
                        std::io::ErrorKind::UnexpectedEof,
                        "Herdr subscription disconnected",
                    )
                    .into());
                }
                Ok(count) => {
                    self.pending.extend_from_slice(&bytes[..count]);
                    if self.pending.len() > MAX_FRAME {
                        bail!("oversized Herdr event");
                    }
                }
                Err(error)
                    if matches!(
                        error.kind(),
                        std::io::ErrorKind::TimedOut | std::io::ErrorKind::WouldBlock
                    ) =>
                {
                    return Ok(None);
                }
                Err(error) if error.kind() == std::io::ErrorKind::Interrupted => {}
                Err(error) => return Err(error.into()),
            }
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn partial_events_survive_read_timeouts() {
        let (reader, mut writer) = UnixStream::pair().unwrap();
        reader
            .set_read_timeout(Some(Duration::from_millis(20)))
            .unwrap();
        let mut events = Events {
            stream: reader,
            pending: Vec::new(),
        };
        writer.write_all(b"{\"event\":\"pane.").unwrap();
        assert!(
            events
                .next(Some(Duration::from_millis(20)))
                .unwrap()
                .is_none()
        );
        assert!(
            events
                .next(Some(Duration::from_millis(20)))
                .unwrap()
                .is_none()
        );
        writer.write_all(b"updated\",\"data\":{}}\n").unwrap();
        assert_eq!(
            events
                .next(Some(Duration::from_millis(20)))
                .unwrap()
                .unwrap()["event"],
            "pane.updated"
        );
    }

    #[test]
    fn api_errors_are_not_successes() {
        assert!(result(json!({"id": "autoname", "error": {"code": "not_found"}})).is_err());
        assert!(result(json!({"id": "autoname"})).is_err());
    }
}
