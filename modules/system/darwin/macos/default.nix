{ self, ... }:
{
  flake.modules.darwin.macos-defaults = {
    imports = with self.modules.darwin; [
      dock
      finder
      keybinds
      keyboard
      power
      safari
      screencapture
      trackpad
      unshittify
      windowmanager
    ];
  };
}
