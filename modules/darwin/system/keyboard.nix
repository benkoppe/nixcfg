{
  config,
  lib,
  self,
  ...
}:
{
  options.myDarwin.system.keyboard.enable = lib.mkEnableOption "sensible keyboard configuration";

  config = lib.mkIf config.myDarwin.system.keyboard.enable {
    system.defaults.NSGlobalDomain = {
      AppleKeyboardUIMode = 2; # Full keyboard UI control.
      ApplePressAndHoldEnabled = false; # No ligatures when holding a key, just repeat it

      "com.apple.keyboard.fnState" = false; # Don't invert Fn.

      InitialKeyRepeat = 15; # N * 15ms to start repeating, so about 150ms
      KeyRepeat = 2; # N * 15ms, so 15ms between each keypress, about 66 per second

      NSAutomaticCapitalizationEnabled = false;
      NSAutomaticDashSubstitutionEnabled = false;
      NSAutomaticInlinePredictionEnabled = false;
      NSAutomaticPeriodSubstitutionEnabled = false;
      NSAutomaticQuoteSubstitutionEnabled = false;
    };

    system.defaults.CustomSystemPreferences."com.apple.CoreBrightness" = {
      "Keyboard Dim Time" = 60;
      KeyboardBacklight.KeyboardBacklightIdleDimTime = 60;
    };
  };
}
