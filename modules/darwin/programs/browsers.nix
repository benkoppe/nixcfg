{
  config,
  lib,
  ...
}:
{
  options.myDarwin.programs.browsers.enable = lib.mkEnableOption "download browsers with homebrew";

  config = lib.mkIf config.myDarwin.programs.browsers.enable {
    homebrew.casks =
      let
        greedy = name: {
          inherit name;
          greedy = true;
        };
      in
      [
        (greedy "google-chrome")
        (greedy "brave-browser")
        (greedy "helium-browser")
      ];

    home-manager.sharedModules = [
      {
        programs.firefox = {
          enable = true;
        };
      }
      (lib.mkIf config.myDarwin.programs.hammerspoon.enable {
        # open new tabs to the right
        xdg.configFile."hammerspoon/init.lua".text =
          lib.mkAfter # lua
            ''
              newWindowRight = hs.hotkey.new({"ctrl"}, "t", function()
                local app = hs.appfinder.appFromName("Brave")
                app:selectMenuItem({"Tab", "New Tab to the Right"})
              end)

              hs.window.filter.new("Brave Browser")
                :subscribe(hs.window.filter.windowFocused, function() newWindowRight:enable() end)
                :subscribe(hs.window.filter.windowUnfocused, function() newWindowRight:disable() end)
            '';
      })
    ];
  };
}
