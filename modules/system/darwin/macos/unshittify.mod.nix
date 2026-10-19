{
  flake.modules.darwin.unshittify = {
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
