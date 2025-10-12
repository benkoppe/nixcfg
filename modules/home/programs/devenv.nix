{
  config,
  lib,
  pkgs,
  ...
}:
{
  options.myHome.programs.devenv.enable = lib.mkEnableOption "devenv";

  config = lib.mkIf config.myHome.programs.devenv.enable {
    home.packages = [ pkgs.devenv ];

    programs.direnv = {
      enable = true;
      enableBashIntegration = true;
      enableZshIntegration = true;
      nix-direnv.enable = true;

      silent = true;
    };
  };
}
