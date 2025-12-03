{
  config,
  lib,
  pkgs,
  self,
  inputs,
  inputs',
  ...
}:
{
  options.myHome.profiles.base.enable = lib.mkEnableOption "base home configuration";

  imports = [
    self.snippetsModule
    inputs.ragenix.homeManagerModules.default
  ];

  config = lib.mkIf config.myHome.profiles.base.enable {
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

      inputs'.colmena.packages.colmena
    ];
  };
}
