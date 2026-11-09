{
  flake.modules.hjem.rex-resume =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      cfg = config.programs.rex.resume;

      json = pkgs.formats.json { };

      # The SessionStart hook for Claude Code and Codex.
      hook = pkgs.writers.writePython3Bin "rex-resume-hook" {
        libraries = [ pkgs.python3Packages.psutil ];
        flakeIgnore = [ "E501" ];
      } (builtins.readFile ./hook.py);

      claudePlugin = pkgs.runCommand "rex-resume-claude-plugin" { } ''
        install -Dm644 ${json.generate "plugin.json" { name = "rex-resume"; }} \
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

      zshInit = pkgs.replaceVars ./rex-resume.zsh {
        inherit claudePlugin;
        opencodePlugin = "${./opencode-plugin}";
        claudeCommand = cfg.commands.claude;
        opencodeCommand = cfg.commands.opencode;
        codexCommand = cfg.commands.codex;
        piCommand = cfg.commands.pi;
        rerunCommands = lib.escapeShellArgs cfg.rerun;
      };
    in
    {
      options.programs.rex.resume = {
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

        rerun = lib.mkOption {
          type = lib.types.listOf lib.types.str;
          default = [
            "v"
            "nvim"
            "vim"
            "less"
            "man"
            "htop"
            "btop"
          ];
          description = ''
            Programs that a restored Rex pane runs again without asking. Any
            other command that was running comes back on the prompt instead.
          '';
        };
      };

      config = {
        # Codex runs the hook by name, so its trusted hash survives rebuilds.
        packages = [ hook ];

        files.".pi/agent/extensions/rex-resume.js".source = "${./pi-extension.js}";

        rum.programs.zsh.initConfig = lib.mkAfter ''
          source ${zshInit}
        '';
      };
    };
}
