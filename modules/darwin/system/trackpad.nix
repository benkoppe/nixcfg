{
  config,
  lib,
  self,
  ...
}:
{
  options.myDarwin.system.trackpad.enable = lib.mkEnableOption "sensible trackpad configuration";

  config = lib.mkIf config.myDarwin.system.trackpad.enable {
    system.defaults.trackpad = {
      Clicking = true; # touch-to-click
      Dragging = false; # tap-to-drag
      TrackpadThreeFingerDrag = false;
    };

    system.defaults.CustomSystemPreferences."com.apple.AppleMultitouchTrackpad" = {
      # Smooth clicking.
      FirstClickThreshold = 0;
      SecondClickThreshold = 0;

      TrackpadThreeFingerVertSwipeGesture = 0; # Four finger swipe up for mission control.

      # Disable 3 finger horizontal stuff.
      TrackpadFourFingerHorizSwipeGesture = 0;
      TrackpadThreeFingerHorizSwipeGesture = 0;
    };

    system.defaults.NSGlobalDomain = {
      "com.apple.trackpad.scaling" = 1.0; # Mouse speed.

      ApplePressAndHoldEnabled = false;

      "com.apple.mouse.tapBehavior" = 1;
      "com.apple.sound.beep.volume" = 0.0;
      "com.apple.sound.beep.feedback" = 0;
    };
  };
}
