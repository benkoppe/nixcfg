{
  config,
  lib,
  ...
}:
{
  options.myDarwin.system.keybinds.enable =
    lib.mkEnableOption "custom builtin keybinds configuration";

  config = lib.mkIf config.myDarwin.system.keybinds.enable {
    system.defaults.CustomUserPreferences."com.apple.symbolichotkeys".AppleSymbolicHotKeys = {
      # Disable 'Cmd + Opt + D' for toggling dock autohide
      "52" = {
        enabled = false;
      };

      # Disable kCGSHotKeySelectPrevious and SelectNextInputSource
      "60" = {
        enabled = false;
      };
      "61" = {
        enabled = false;
      };

      # Disable 'Cmd + space' for spotlight search
      "64" = {
        enabled = false;
      };
      # Disable 'Cmd + Alt + space' for finder search window
      "65" = {
        enabled = false;
      };

      # Disable double-tap 'Cmd' for siri
      "176" = {
        enabled = false;
      };
    };
  };
}
