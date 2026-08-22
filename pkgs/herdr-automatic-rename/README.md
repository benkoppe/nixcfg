# herdr-automatic-rename

Private Herdr 0.8.2+ plugin for:

- display-only bare workspace jump indexes through `$automatic_rename_index`;
- display-only bare agent jump indexes in grouped (`spaces`) order;
- automatic tab names with `[N]` prefixes;
- manual tab rename opt-out and a `reset` action.

The plugin is event-driven and intentionally has no shell hook. Ordinary foreground command changes settle on the next subscribed Herdr event.

Required Herdr sidebar configuration:

```toml
[ui.sidebar.agents]
rows = [
  ["state_icon", "$automatic_rename_index", "workspace", "tab"],
  ["agent"],
]

[ui.sidebar.spaces]
rows = [
  ["state_icon", "$automatic_rename_index", "workspace"],
  ["branch", "git_status"],
]
```

Build and test directly:

```sh
cargo test
cargo clippy --all-targets -- -D warnings
nix build --impure --expr '
  let
    flake = builtins.getFlake (toString ../..);
    pkgs = flake.inputs.nixpkgs.legacyPackages.${builtins.currentSystem};
  in pkgs.callPackage ./default.nix {}
'
```
