{
  config,
  lib,
  pkgs,
  self,
  ...
}:
{
  options.myHome.profiles.base.enable = lib.mkEnableOption "base home configuration";

  config = lib.mkIf config.myHome.profiles.base.enable {
    myHome.programs = {
      git.enable = true;
      vim.enable = true;
      tmux.enable = true;
    };

    home.packages = with pkgs; [
      # General packages for development and system management
      nh
      coreutils
      bash-completion
      killall
      wget
      zip
      unzip

      # Text/data tools
      jq
      ripgrep
      fd
      tree

      # Security / crypto
      gnupg
      age
      age-plugin-yubikey
      libfido2

      # Monitoring and diagnostics
      htop
      iftop
    ];
  };
}
