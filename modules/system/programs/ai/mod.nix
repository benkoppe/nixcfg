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
    imports = with self.modules.hjem; [
      mcp
      skills
    ];

    agents.skills.sources = [ "${inputs.pstack}/pstack/skills" ];

    agents.skills.entries = {
      iterative-plan-critic = ./skills/iterative-plan-critic;
    };
  };

  flake.modules.hjem.codex =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      inherit (pkgs.stdenv.hostPlatform) system;

      mcpServers = lib.mapAttrs (
        _: s:
        {
          inherit (s) enabled;
        }
        // (
          if s.url != null then
            { inherit (s) url; } // lib.optionalAttrs (s.headers != { }) { http_headers = s.headers; }
          else
            { inherit (s) command args; } // lib.optionalAttrs (s.env != { }) { inherit (s) env; }
        )
      ) config.agents.mcp.servers;
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

          mcp_servers = mcpServers;
        };
      };
    };

  flake.modules.hjem.claude-code =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      inherit (pkgs.stdenv.hostPlatform) system;

      json = pkgs.formats.json { };

      mcpJson = json.generate "claude-mcps.json" {
        mcpServers = lib.mapAttrs (
          _: s:
          if s.url != null then
            {
              type = "http";
              inherit (s) url;
            }
            // lib.optionalAttrs (s.headers != { }) { inherit (s) headers; }
          else
            {
              type = "stdio";
              inherit (s) command args;
            }
            // lib.optionalAttrs (s.env != { }) { inherit (s) env; }
        ) (lib.filterAttrs (_: s: s.enabled) config.agents.mcp.servers);
      };

      mcpPlugin = pkgs.runCommand "claude-nix-plugin" { } ''
        install -Dm644 ${json.generate "plugin.json" { name = "nix"; }} $out/.claude-plugin/plugin.json
        install -Dm644 ${mcpJson} $out/.mcp.json
      '';
    in
    {
      imports = with self.modules.hjem; [ ai-setup ];

      packages = [
        inputs.llm-agents.packages.${system}.claude-code
        pkgs.ripgrep
      ];

      agents.skills.targets = [ ".claude/skills" ];

      files.".claude/skills/nix-mcps".source = mcpPlugin;

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
