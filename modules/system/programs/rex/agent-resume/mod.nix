{
  flake.modules.hjem.rex-agent-resume =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      cfg = config.programs.rex.agentResume;

      json = pkgs.formats.json { };

      # The SessionStart hook for Claude Code and Codex.
      hook = pkgs.writers.writePython3Bin "rex-agent-resume-hook" {
        libraries = [ pkgs.python3Packages.psutil ];
        flakeIgnore = [ "E501" ];
      } (builtins.readFile ./hook.py);

      claudePlugin = pkgs.runCommand "rex-agent-resume-claude-plugin" { } ''
        install -Dm644 ${json.generate "plugin.json" { name = "rex-agent-resume"; }} \
          $out/.claude-plugin/plugin.json
        install -Dm644 ${
          json.generate "hooks.json" {
            hooks.SessionStart = [
              {
                hooks = [
                  {
                    type = "command";
                    command = "${lib.getExe hook} claude";
                  }
                ];
              }
            ];
          }
        } $out/hooks/hooks.json
      '';

      zshInit = pkgs.replaceVars ./rex-agent-resume.zsh {
        inherit claudePlugin;
        opencodePlugin = "${./opencode-plugin}";
        claudeCommand = cfg.commands.claude;
        opencodeCommand = cfg.commands.opencode;
        codexCommand = cfg.commands.codex;
        piCommand = cfg.commands.pi;
      };
    in
    {
      options.programs.rex.agentResume = {
        commands = lib.mkOption {
          type = lib.types.submodule {
            options = {
              claude = lib.mkOption {
                type = lib.types.str;
                default = "claude";
              };
              opencode = lib.mkOption {
                type = lib.types.str;
                default = "opencode2";
              };
              codex = lib.mkOption {
                type = lib.types.str;
                default = "codex";
              };
              pi = lib.mkOption {
                type = lib.types.str;
                default = "pi";
              };
            };
          };
          default = { };
        };
      };

      config = {
        # Codex runs the hook by name, so its trusted hash survives rebuilds.
        packages = [ hook ];

        files.".pi/agent/extensions/rex-agent-resume.js".source = ./pi-extension.js;

        rum.programs.zsh.initConfig = lib.mkAfter ''
          source ${zshInit}
        '';
      };
    };
}
