{
  config,
  lib,
  pkgs,
  self,
  inputs,
  ...
}:
{
  options.myHome.profiles.base.enable = lib.mkEnableOption "base home configuration";

  imports = [
    self.snippetsModule
    inputs.ragenix.homeManagerModules.default
  ];

  config = lib.mkIf config.myHome.profiles.base.enable (
    lib.mkMerge [
      {
        myHome.programs = {
          git.enable = true;
          vim.enable = true;
          tmux.enable = true;
        };

        programs.home-manager.enable = true;
        xdg.enable = true;

        home.packages = with pkgs; [
          # General packages for development and system management
          nh
          nix-output-monitor
          coreutils
          bash-completion
          killall
          wget
          zip
          unzip

          # Monitoring and diagnostics
          htop
          iftop
        ];

        home.stateVersion = "25.05";
      }

      (lib.mkIf pkgs.stdenv.isLinux {
        home = {
          homeDirectory = lib.mkDefault "/home/${config.home.username}";
        };
      })

      (lib.mkIf pkgs.stdenv.isDarwin {
        home = {
          enableNixpkgsReleaseCheck = false;
          homeDirectory = "/Users/${config.home.username}";
        };
      })
    ]
  );
}
