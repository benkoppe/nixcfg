{ lib, ... }:
{
  flake.modules.darwin.finder =
    { config, ... }:
    {
      system.defaults.NSGlobalDomain = {
        AppleShowAllFiles = true;
        AppleShowAllExtensions = true;

        "com.apple.springing.enabled" = true;
        "com.apple.springing.delay" = 0.0;
      };

      system.defaults.CustomSystemPreferences."com.apple.desktopservices" = {
        DSDontWriteNetworkStores = true;
        DSDontWriteUSBStores = true;
      };

      system.defaults.finder = {
        AppleShowAllExtensions = true;
        AppleShowAllFiles = true;

        FXEnableExtensionChangeWarning = true;
        FXPreferredViewStyle = "Nlsv"; # List style.
        FXRemoveOldTrashItems = true;

        _FXShowPosixPathInTitle = true;
        _FXSortFoldersFirst = true;
        _FXSortFoldersFirstOnDesktop = false;

        NewWindowTarget = "Home";

        QuitMenuItem = true; # Allow quitting of Finder application

        ShowExternalHardDrivesOnDesktop = true;
        ShowMountedServersOnDesktop = true;
        ShowPathbar = true;
        ShowRemovableMediaOnDesktop = true;
        ShowStatusBar = true;
      };

      system.defaults.CustomSystemPreferences."com.apple.finder" = {
        DisableAllAnimations = true;

        FXArrangeGroupViewBy = "Name";
        FxDefaultSearchScope = "SCcf"; # Search in current folder by default.

        WarnOnEmptyTrash = false;
      };

      # Unhide ~/Library
      system.activationScripts.script.text = lib.mkAfter ''
        ${config.system.activationScripts.unhide-library.text}
      '';
      system.activationScripts.unhide-library.text = /* bash */ ''
        echo "unhiding ~/Library..."
        /usr/bin/chflags nohidden ~/Library
      '';
    };
}
