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

      claudeHook = pkgs.writers.writePython3Bin "rex-agent-resume-claude-hook" {
        libraries = [ pkgs.python3Packages.psutil ];
        flakeIgnore = [ "E501" ];
      } (builtins.readFile ./claude-hook.py);

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
                    command = lib.getExe claudeHook;
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
            };
          };
        };
      };

      config = {
        rum.programs.zsh.initConfig = lib.mkAfter ''
          source ${zshInit}
        '';
      };
    };
}
