{ self, inputs, ... }:
{
  flake.modules.hjem.ai = {
    imports = with self.modules.hjem; [
      opencode
      pi
      codex
      claude-code
      claudex
    ];
  };

  flake.modules.hjem.codex =
    { pkgs, ... }:
    let
      inherit (pkgs.stdenv.hostPlatform) system;
    in
    {
      packages = [
        inputs.llm-agents.packages.${system}.codex
      ];

      xdg.config.files."codex/config.toml".type = "copy";
      xdg.config.files."codex/config.toml".generator = pkgs.writers.writeTOML "codex-config.toml";
      xdg.config.files."codex/config.toml".value = {
        approval_policy = "on-request";
        check_for_update_on_startup = false;
        commit_attribution = "";

        default_permissions = "default";
        permissions.default = {
          extends = ":workspace";

          filesystem = {
            ":root" = "deny";
            ":minimal" = "read";
            ":workspace_roots"."." = "write";
            ":workspace_roots".".git" = "write";
          };

          network.enabled = true;
          network.domains."*" = "allow";
        };
      };
    };

  flake.modules.hjem.claude-code =
    { pkgs, ... }:
    let
      inherit (pkgs.stdenv.hostPlatform) system;
    in
    {
      packages = [
        inputs.llm-agents.packages.${system}.claude-code
      ];

      files.".claude/settings.json".type = "copy";
      files.".claude/settings.json".generator = builtins.toJSON;
      files.".claude/settings.json".value = {
        "$schema" = "https://json.schemastore.org/claude-code-settings.json";

        env.CLAUDE_BASH_NO_LOGIN = "1";
        env.CLAUDE_CODE_EAGER_FLUSH = "1";
        env.CLAUDE_CODE_FORCE_GLOBAL_CACHE = "1";
        env.MCP_CONNECTION_NONBLOCKING = "1";
        env.USE_BUILTIN_RIPGREP = "0";

        alwaysThinkingEnabled = true;
        env.CLAUDE_CODE_DISABLE_ADAPTIVE_THINKING = "1";
        env.CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS = "1";
        env.CLAUDE_CODE_MAX_TOOL_USE_CONCURRENCY = "20";
        env.CLAUDE_CODE_PLAN_V2_AGENT_COUNT = "5";
        env.CLAUDE_CODE_PLAN_V2_EXPLORE_AGENT_COUNT = "5";
        env.DISABLE_AUTO_COMPACT = "1";
        env.ENABLE_MCP_LARGE_OUTPUT_FILES = "1";
        env.ENABLE_TOOL_SEARCH = "auto:5";
        env.MAX_THINKING_TOKENS = "31999";

        skipWebFetchPreflight = true;
        env.CLAUDE_CODE_DISABLE_FEEDBACK_SURVEY = "1";
        env.DISABLE_AUTOUPDATER = "1";
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
        includeCoAuthoredBy = false;

        env.CLAUDE_CODE_DISABLE_TERMINAL_TITLE = "1";
        env.CLAUDE_CODE_HIDE_ACCOUNT_INFO = "1";
        # env.DISABLE_COST_WARNINGS = "1";

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

  flake.modules.hjem.claudex =
    { pkgs, ... }:
    let
      inherit (pkgs.stdenv.hostPlatform) system;
    in
    {
      packages = [
        (pkgs.writeShellScriptBin "claudex" ''
          export CLAUDE_CODE_SUBAGENT_MODEL="gpt-5.6-sol"
          export CLAUDE_CODE_ALWAYS_ENABLE_EFFORT=1
          export CLAUDE_CODE_MAX_TOOL_USE_CONCURRENCY=3
          export ENABLE_TOOL_SEARCH=false
          export ANTHROPIC_BASE_URL="http://127.0.0.1:8317"
          export ANTHROPIC_AUTH_TOKEN="sk-dummy"

          exec ${inputs.llm-agents.packages.${system}.claude-code}/bin/claude \
            --model "gpt-5.6-sol" \
            "$@"
        '')
      ];
    };
}
