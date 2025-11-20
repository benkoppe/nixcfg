{
  config,
  lib,
  ...
}:
{
  options.myDarwin.system.unshittify.enable = lib.mkEnableOption "unshittify macOS system defaults";

  config = lib.mkIf config.myDarwin.system.unshittify.enable {
    system.defaults = {
      NSGlobalDomain = {
        NSDocumentSaveNewDocumentsToCloud = false;
      };

      LaunchServices = {
        LSQuarantine = false;
      };

      CustomSystemPreferences."com.apple.AdLib" = {
        allowApplePersonalizedAdvertising = false;
        allowIdentifierForAdvertising = false;
        forceLimitAdTracking = true;
        personalizedAdsMigrated = false;
      };
    };
  };
}
