{
  config,
  lib,
  self,
  ...
}:
{
  options.myDarwin.system.screencapture.enable =
    lib.mkEnableOption "sensible screencapture configuration";

  config = lib.mkIf config.myDarwin.system.screencapture.enable {
    system.defaults.screencapture = {
      location = "~/Downloads";

      include-date = true;
    };
  };
}
