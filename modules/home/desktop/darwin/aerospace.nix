{
  config,
  lib,
  darwinConfig ? null,
  ...
}:
{
  options.myHome.desktop.darwin.aerospace.enable =
    lib.mkEnableOption "use Aerospace for macOS window management";

  config = lib.mkIf config.myHome.desktop.darwin.aerospace.enable (
    lib.mkMerge [
      {

        programs.aerospace = {
          enable = true;

          launchd = {
            enable = true;
            keepAlive = true;
          };

          settings = {
            # Disable all native main keybinds (no F19 modifier key)
            mode.main.binding = { };

            mode.resize.binding = {
              h = "resize width -50";
              j = "resize height +50";
              k = "resize height -50";
              l = "resize width +50";

              f = "fullscreen";
              b = "balance-sizes";

              enter = "mode main";
              esc = "mode main";
            };

            on-window-detected = [
              {
                "if".app-id = "com.mitchellh.ghostty";
                run = [ "layout floating" ];
              }
              {
                "if".app-name-regex-substring = "finder";
                run = [ "layout floating" ];
              }
              {
                "if".app-name-regex-substring = "qemu-system-*";
                run = [ "layout floating" ];
              }
              {
                "if".window-title-regex-substring = "Bitwarden";
                run = [ "layout floating" ];
              }
            ];
          };
        };

      }
      (lib.mkIf (darwinConfig != null && darwinConfig.myDarwin.programs.hammerspoon.enable) {
        # Configure keybinds with hammerspoon instead.
        xdg.configFile."hammerspoon/init.lua".text =
          lib.mkAfter # lua
            ''
              local AEROSPACE = "${config.home.homeDirectory}/.nix-profile/bin/aerospace"

              function aerospaceExec(cmd)
                os.execute("nohup " .. AEROSPACE .. " " .. cmd .. " &")
              end

              function aerospaceSwipe(cmd)
                aerospaceExec("workspace --no-stdin " .. cmd)
              end

              ----- KEY BINDS -----

              -- FOCUS (with wrapping)
              hyper:bind({}, "h", nil, function() aerospaceExec("focus --boundaries-action wrap-around-the-workspace left") end)
              hyper:bind({}, "j", nil, function() aerospaceExec("focus --boundaries-action wrap-around-the-workspace down") end)
              hyper:bind({}, "k", nil, function() aerospaceExec("focus --boundaries-action wrap-around-the-workspace up") end)
              hyper:bind({}, "l", nil, function() aerospaceExec("focus --boundaries-action wrap-around-the-workspace right") end)

              -- MOVE
              hyper:bind({"shift"}, "h", nil, function() aerospaceExec("move left") end)
              hyper:bind({"shift"}, "j", nil, function() aerospaceExec("move down") end)
              hyper:bind({"shift"}, "k", nil, function() aerospaceExec("move up") end)
              hyper:bind({"shift"}, "l", nil, function() aerospaceExec("move right") end)

              -- JOIN
              hyper:bind({"cmd"}, "h", nil, function() aerospaceExec("join-with left") end)
              hyper:bind({"cmd"}, "j", nil, function() aerospaceExec("join-with down") end)
              hyper:bind({"cmd"}, "k", nil, function() aerospaceExec("join-with up") end)
              hyper:bind({"cmd"}, "l", nil, function() aerospaceExec("join-with right") end)

              -- RESIZE
              hyper:bind({"alt"}, "h", nil, function() aerospaceExec("resize width -50") end)
              hyper:bind({"alt"}, "j", nil, function() aerospaceExec("resize height +50") end)
              hyper:bind({"alt"}, "k", nil, function() aerospaceExec("resize height -50") end)
              hyper:bind({"alt"}, "l", nil, function() aerospaceExec("resize width +50") end)
              hyper:bind({"alt"}, "b", nil, function() aerospaceExec("balance-sizes") end)

              hyper:bind({}, "-", nil, function() aerospaceExec("resize smart -50") end)
              hyper:bind({}, "=", nil, function() aerospaceExec("resize smart +50") end)
              hyper:bind({}, "r", nil, function() aerospaceExec("mode resize") end)
              hyper:bind({}, "f", nil, function() aerospaceExec("fullscreen") end)

              -- LAYOUT
              hyper:bind({}, "space", nil, function() aerospaceExec("layout floating tiling") end)
              hyper:bind({}, ",", nil, function() aerospaceExec("layout tiles horizontal vertical") end)
              hyper:bind({}, ".", nil, function() aerospaceExec("layout accordion horizontal vertical") end)

              -- CLOSE
              hyper:bind({}, "q", nil, function() aerospaceExec("close") end)

              -- WORKSPACE JUMP
              hyper:bind({}, "1", nil, function() aerospaceExec("workspace 1") end)
              hyper:bind({}, "2", nil, function() aerospaceExec("workspace 2") end)
              hyper:bind({}, "3", nil, function() aerospaceExec("workspace 3") end)
              hyper:bind({}, "4", nil, function() aerospaceExec("workspace 4") end)
              hyper:bind({}, "5", nil, function() aerospaceExec("workspace 5") end)
              hyper:bind({}, "6", nil, function() aerospaceExec("workspace 6") end)
              hyper:bind({}, "7", nil, function() aerospaceExec("workspace 7") end)
              hyper:bind({}, "8", nil, function() aerospaceExec("workspace 8") end)
              hyper:bind({}, "9", nil, function() aerospaceExec("workspace 9") end)
              hyper:bind({}, "0", nil, function() aerospaceExec("workspace 10") end)

              -- WORKSPACE JUMP - SECOND LAYER
              hyper:bind({"cmd"}, "1", nil, function() aerospaceExec("workspace 11") end)
              hyper:bind({"cmd"}, "2", nil, function() aerospaceExec("workspace 12") end)
              hyper:bind({"cmd"}, "3", nil, function() aerospaceExec("workspace 13") end)
              hyper:bind({"cmd"}, "4", nil, function() aerospaceExec("workspace 14") end)
              hyper:bind({"cmd"}, "5", nil, function() aerospaceExec("workspace 15") end)
              hyper:bind({"cmd"}, "6", nil, function() aerospaceExec("workspace 16") end)
              hyper:bind({"cmd"}, "7", nil, function() aerospaceExec("workspace 17") end)
              hyper:bind({"cmd"}, "8", nil, function() aerospaceExec("workspace 18") end)
              hyper:bind({"cmd"}, "9", nil, function() aerospaceExec("workspace 19") end)
              hyper:bind({"cmd"}, "0", nil, function() aerospaceExec("workspace 20") end)

              -- WORKSPACE MOVE
              hyper:bind({"shift"}, "1", nil, function() aerospaceExec("move-node-to-workspace 1") end)
              hyper:bind({"shift"}, "2", nil, function() aerospaceExec("move-node-to-workspace 2") end)
              hyper:bind({"shift"}, "3", nil, function() aerospaceExec("move-node-to-workspace 3") end)
              hyper:bind({"shift"}, "4", nil, function() aerospaceExec("move-node-to-workspace 4") end)
              hyper:bind({"shift"}, "5", nil, function() aerospaceExec("move-node-to-workspace 5") end)
              hyper:bind({"shift"}, "6", nil, function() aerospaceExec("move-node-to-workspace 6") end)
              hyper:bind({"shift"}, "7", nil, function() aerospaceExec("move-node-to-workspace 7") end)
              hyper:bind({"shift"}, "8", nil, function() aerospaceExec("move-node-to-workspace 8") end)
              hyper:bind({"shift"}, "9", nil, function() aerospaceExec("move-node-to-workspace 9") end)
              hyper:bind({"shift"}, "0", nil, function() aerospaceExec("move-node-to-workspace 10") end)

              -- WORKSPACE MOVE - SECOND LAYER
              hyper:bind({"shift", "cmd"}, "1", nil, function() aerospaceExec("move-node-to-workspace 11") end)
              hyper:bind({"shift", "cmd"}, "2", nil, function() aerospaceExec("move-node-to-workspace 12") end)
              hyper:bind({"shift", "cmd"}, "3", nil, function() aerospaceExec("move-node-to-workspace 13") end)
              hyper:bind({"shift", "cmd"}, "4", nil, function() aerospaceExec("move-node-to-workspace 14") end)
              hyper:bind({"shift", "cmd"}, "5", nil, function() aerospaceExec("move-node-to-workspace 15") end)
              hyper:bind({"shift", "cmd"}, "6", nil, function() aerospaceExec("move-node-to-workspace 16") end)
              hyper:bind({"shift", "cmd"}, "7", nil, function() aerospaceExec("move-node-to-workspace 17") end)
              hyper:bind({"shift", "cmd"}, "8", nil, function() aerospaceExec("move-node-to-workspace 18") end)
              hyper:bind({"shift", "cmd"}, "9", nil, function() aerospaceExec("move-node-to-workspace 19") end)
              hyper:bind({"shift", "cmd"}, "0", nil, function() aerospaceExec("move-node-to-workspace 20") end)

              -- WORKSPACE TAB
              hyper:bind({}, "tab", nil, function() aerospaceExec("workspace-back-and-forth") end)
              hyper:bind({"shift"}, "tab", nil, function() aerospaceExec("move-workspace-to-monitor --wrap-around next") end)

              -- WORKSPACE SWITCH
              hyper:bind({}, "right", nil, function() aerospaceSwipe("--wrap-around next") end)
              hyper:bind({}, "n", nil, function() aerospaceSwipe("--wrap-around next") end)
              hyper:bind({}, "left", nil, function() aerospaceSwipe("--wrap-around prev") end)
              hyper:bind({}, "p", nil, function() aerospaceSwipe("--wrap-around prev") end)
            '';
      })
    ]
  );
}
