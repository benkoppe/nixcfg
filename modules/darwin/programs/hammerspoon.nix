{ config, lib, ... }:
{
  options.myDarwin.programs.hammerspoon.enable =
    lib.mkEnableOption "enable Hammerspoon for macOS automation";

  config = lib.mkIf config.myDarwin.programs.hammerspoon.enable {
    system.defaults.CustomUserPreferences."org.hammerspoon.Hammerspoon".MJConfigFile =
      "~/.config/hammerspoon/init.lua";

    homebrew.casks = [
      {
        name = "hammerspoon";
        greedy = true;
      }
    ];

    home-manager.sharedModules = [
      {
        # Do hyper keys on darwin with hyper
        # from https://github.com/evantravers/hammerspoon-config/blob/38a7d8c0ad2190d1563d681725628e4399dcbe6c/hyper.lua
        xdg.configFile."hammerspoon/hyper.lua".text = /* lua */ ''
          local hyper = hs.hotkey.modal.new({}, nil)

          hyper.pressed = function()
            hyper:enter()
          end

          hyper.released = function()
            hyper:exit()
          end

          -- Set the key you want to be HYPER to F19 in karabiner or keyboard
          -- Bind the Hyper key to the hammerspoon modal
          hs.hotkey.bind({}, 'F19', hyper.pressed, hyper.released)

          hyper.allowed = function(app)
            if app.tags then
              if hs.settings.get("only") then
                return hs.fnutils.some(hs.settings.get("only"), function(tag)
                  return hs.fnutils.contains(app.tags, tag)
                end)
              else
                if hs.settings.get("never") then
                  return hs.fnutils.every(hs.settings.get("never"), function(tag)
                    return not hs.fnutils.contains(app.tags, tag)
                  end)
                end
              end
            end
            return true
          end

          hyper.launch = function(app)
            if hyper.allowed(app) then
              hs.application.launchOrFocusByBundleID(app.bundleID)
            else
              hs.notify.show("Blocked " .. app.bundleID, "You have to switch headspaces", "")
            end
          end

          -- Expects a configuration table with an applications key that has the
          -- following form:
          -- config_table.applications = {
          --   ['com.culturedcode.ThingsMac'] = {
          --     bundleID = 'com.culturedcode.ThingsMac',
          --     hyper_key = 't',
          --     tags = {'#planning', '#review'},
          --     local_bindings = {',', '.'}
          --   },
          -- }
          hyper.start = function(config_table)
            -- Use the hyper key with the application config to use the `hyper_key`
            for _, app in pairs(config_table.applications) do
              -- Apps that I want to jump to
              if app.hyper_key then
                hyper:bind({}, app.hyper_key, function() hyper.launch(app); end)
              end

              -- I use hyper to power some shortcuts in different apps If the app is closed
              -- and I press the shortcut, open the app and send the shortcut, otherwise
              -- just send the shortcut.
              if app.local_bindings then
                for _, key in pairs(app.local_bindings) do
                  hyper:bind({}, key, nil, function()
                    if hs.application.find(app.bundleID) then
                      hs.eventtap.keyStroke({'cmd','alt','shift','ctrl'}, key)
                    else
                      hyper.launch(app)
                      hs.timer.waitWhile(
                        function() return hs.application.find(app.bundleID) == nil end,
                        function()
                          hs.eventtap.keyStroke({'cmd','alt','shift','ctrl'}, key)
                        end)
                    end
                  end)
                end
              end
            end
          end

          return hyper

        '';

        xdg.configFile."hammerspoon/init.lua".text = # lua
          ''
            config = {}
            config.applications = {
              ['Alfred'] = {
                bundleID = 'com.runningwithcrayons.Alfred',
              },
              ['Brave'] = {
                bundleID = 'com.brave.Browser',
                hyper_key = 'b',
              },
              ['Ghostty'] = {
                bundleID = 'com.mitchellh.ghostty',
                hyper_key = 'return',
              },
              ['Xcode'] = {
                bundleID = 'com.apple.dt.Xcode',
                hyper_key = 'x',
              },
              ['Discord'] = {
                bundleID = 'com.hammerandchisel.discord',
                hyper_key = 'd',
              },
            }

            hyper = require('hyper')
            hyper.start(config)

            hyper:bind({'cmd', 'shift'}, 'r', nil, function() hs.console.hswindow():focus() end)
            hyper:bind({'cmd'}, 'r', nil, function() hs.reload() end)
          '';
      }
    ];
  };
}
