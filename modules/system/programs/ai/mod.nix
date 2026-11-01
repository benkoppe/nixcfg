{ self, inputs, ... }:
{
  flake.modules.hjem.ai = {
    imports = with self.modules.hjem; [
      opencode
      pi
      codex
      claude-code
    ];
  };

  flake.modules.hjem.ai-setup = {
    key = "nixcfg#hjem.ai-setup";
    imports = with self.modules.hjem; [ mcp ];
  };

  flake.modules.hjem.codex =
    { pkgs, ... }:
    let
      inherit (pkgs.stdenv.hostPlatform) system;
    in
    {
      imports = with self.modules.hjem; [ ai-setup ];

      packages = [
        inputs.llm-agents.packages.${system}.codex
      ];

      xdg.config.files."codex/config.toml" = {
        type = "copy";
        generator = pkgs.writers.writeTOML "codex-config.toml";
        value = {
          approval_policy = "on-request";
          check_for_update_on_startup = false;
          commit_attribution = "";
        };
      };
    };

  flake.modules.hjem.claude-code =
    { pkgs, ... }:
    let
      inherit (pkgs.stdenv.hostPlatform) system;
    in
    {
      imports = with self.modules.hjem; [ ai-setup ];

      packages = [
        inputs.llm-agents.packages.${system}.claude-code
        pkgs.ripgrep
      ];

      files.".claude/settings.json" = {
        type = "copy";
        generator = builtins.toJSON;
        value = {
          "$schema" = "https://json.schemastore.org/claude-code-settings.json";

          env.CLAUDE_CODE_EAGER_FLUSH = "1";
          env.USE_BUILTIN_RIPGREP = "0";

          env.CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS = "1";
          env.DISABLE_AUTO_COMPACT = "1";
          env.ENABLE_TOOL_SEARCH = "auto:5";

          skipWebFetchPreflight = true;
          env.CLAUDE_CODE_DISABLE_FEEDBACK_SURVEY = "1";
          env.DISABLE_UPDATES = "1";
          env.DISABLE_ERROR_REPORTING = "1";
          env.DISABLE_INSTALLATION_CHECKS = "1";
          # env.DISABLE_TELEMETRY = "1";

          enabledPlugins."clangd-lsp@claude-plugins-official" = true;
          enabledPlugins."code-review@claude-plugins-official" = true;
          enabledPlugins."code-simplifier@claude-plugins-official" = true;
          enabledPlugins."ralph-loop@claude-plugins-official" = true;
          enabledPlugins."rust-analyzer-lsp@claude-plugins-official" = true;

          attribution.commit = "";
          attribution.pr = "";

          hooks.SessionStart = [
            {
              matcher = "*";
              hooks = [
                {
                  type = "command";
                  command = ''
                    if [ -f "$HOME/.claude/hooks/herdr-agent-state.sh" ]; then
                      exec bash "$HOME/.claude/hooks/herdr-agent-state.sh" session
                    fi
                  '';
                  timeout = 10;
                }
              ];
            }
          ];
        };
      };
    };
}
