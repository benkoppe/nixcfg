{
  config,
  lib,
  self,
  ...
}:
{
  options.myDarwin.system.windowmanager.enable =
    lib.mkEnableOption "sensible windowmanager configuration";

  config = lib.mkIf config.myDarwin.system.windowmanager.enable (
    lib.mkMerge [
      {
        system.defaults.NSGlobalDomain = {
          _HIHideMenuBar = false; # Only hide menubar on fullscreen.

          AppleInterfaceStyle = "Dark";

          AppleScrollerPagingBehavior = true; # Jump to the spot that was pressed in the scrollbar.
          AppleShowScrollBars = "WhenScrolling";

          NSWindowShouldDragOnGesture = true; # CMD + CTRL click to drag window.
          AppleEnableMouseSwipeNavigateWithScrolls = true; # swipe back to go back
          AppleEnableSwipeNavigateWithScrolls = true;

          AppleWindowTabbingMode = "always"; # Always prefer tabs for new windows.

          NSScrollAnimationEnabled = true;
          NSWindowResizeTime = 0.003;

          NSNavPanelExpandedStateForSaveMode = true; # Expand save panel by default.
          PMPrintingExpandedStateForPrint = true; # Expand print panel by default.

          AppleSpacesSwitchOnActivate = false; # Do not switch workspaces implicitly.
        };

        system.defaults.CustomSystemPreferences."com.apple.dock" = {
          workspaces-auto-swoosh = false; # Don't switch my workspaces for me

          workspaces-edge-delay = 0.0; # Disable opening spaces picker with the upper edge
        };

        system.defaults.WindowManager = {
          AppWindowGroupingBehavior = false; # Show them one at a time.
        };
      }
      (lib.mkIf config.myDarwin.programs.hammerspoon.enable {
        # Disable cmd+h and cmd+shift+h annoying hide commands
        home-manager.sharedModules = [
          {
            xdg.configFile."hammerspoon/init.lua".text =
              lib.mkAfter # lua
                ''
                  hs.hotkey.bind({"cmd"}, "h", function() end)
                  hs.hotkey.bind({"cmd", "shift"}, "h", function() end)
                '';
          }
        ];
      })
    ]
  );
}
