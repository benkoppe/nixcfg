{ config, lib, ... }:
{
  options.myDarwin.programs.homebrew.enable =
    lib.mkEnableOption "strict determinate homebrew configuration";

  config = lib.mkIf config.myDarwin.programs.homebrew.enable {
    homebrew = {
      enable = true;
      global.autoUpdate = false;
      onActivation = {
        upgrade = true;
        cleanup = "zap";
      };
    };
  };
}
