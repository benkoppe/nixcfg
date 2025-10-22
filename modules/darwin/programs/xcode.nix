{ config, lib, ... }:
{
  options.myDarwin.programs.xcode.enable = lib.mkEnableOption "module for xcode-related settings";

  config = lib.mkIf config.myDarwin.programs.xcode.enable (
    lib.mkIf config.myDarwin.programs.hammerspoon.enable {
      home-manager.sharedModules = [
        {
          # format-on-save in xcode with hammerspoon
          xdg.configFile."hammerspoon/init.lua".text =
            lib.mkAfter # lua
              ''
                formatOnSave = hs.hotkey.new({"cmd"}, "s", function()
                  -- Reformat first
                  hs.eventtap.keyStroke({"ctrl", "shift"}, "i", 0)

                  -- Then save, with a tiny delay so Xcode processes the first command
                  hs.timer.doAfter(0.05, function()
                    hs.eventtap.keyStroke({"cmd"}, "s", 0)
                    -- Keep suppression on briefly so our synthetic Cmd+S doesn't retrigger
                    hs.timer.doAfter(0.05, function() suppress = false end)
                  end)
                end)

                hs.window.filter.new("Xcode")
                  :subscribe(hs.window.filter.windowFocused, function() formatOnSave:enable() end)
                  :subscribe(hs.window.filter.windowUnfocused, function() formatOnSave:disable() end)
              '';
        }
      ];
    }
  );
}
