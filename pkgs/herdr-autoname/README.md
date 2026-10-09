# Herdr autoname

Names tabs after an agent's task or the foreground program, with a `[1]`–`[9]`
prefix matching tab order. Requires stock Herdr 0.9.3 or later.

**Rename a tab by hand to keep its name.** To return it to automatic naming,
select it and press **prefix+shift+a**, or run:

```sh
herdr-autoname reset w1:t1
```

## Running it

Herdr's startup hook starts one background updater per session on Linux and
macOS. No systemd or launchd configuration is needed, including with standalone
Hjem. The hook returns immediately; the updater exits when its session socket
closes.

After deploying to an already-running session, start it once:

```sh
herdr-autoname start
```

For a named session, use `herdr-autoname start --session NAME`. Repeated starts
are harmless. There is no automatic crash recovery: run start again if needed.
Diagnostics go to `watch.log` beside that session's ownership state under
`~/.local/state/herdr-autoname/sessions/` (or `$XDG_STATE_HOME`).

If upgrading from the service-based version, stop the old worker first with
`systemctl --user stop herdr-autoname@default`. There are no shell hooks or
Herdr patches.

## Updates and overhead

Agent titles and tab order update through Herdr's socket events. When all
automatic tabs have meaningful agent titles, the updater blocks waiting for
events: **no periodic snapshots or process queries**.

Tabs without an agent task title use foreground-process names. Only those
automatic tabs are checked every two seconds; manual tabs are excluded.
Process results are cached so unrelated events don't multiply these queries.

## Existing names and limitations

Known automatic names are imported from the old state file. Untracked names
are left alone; use reset on any frozen tab you want managed again. State is
locked, written atomically, and kept separately for each session. A damaged
state file is reported rather than silently discarded.

Sidebar numbers assume a single server with expanded worktree groups and
grouped agents. They aren't client-specific. Set `HERDR_AUTONAME_INDEXES=off`
in Herdr's environment for other sidebar views. Tab prefixes still work.

Herdr has no atomic compare-and-rename API. The updater checks for a manual
rename before writing, but cannot guarantee which wins if both happen at
exactly the same time.

## Development

```sh
cargo test
cargo clippy --all-targets -- -D warnings
cargo fmt --check
```

Tests use isolated mock servers, not your running session.
