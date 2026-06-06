{
  flake.modules.nixos.niri =
    { pkgs, ... }:
    {
      # We need an XDG portal for various applications to work properly,
      # such as Flatpak applications.
      xdg.portal = {
        enable = true;
        extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
        config.common.default = "*";
      };

      environment.systemPackages = with pkgs; [ xwayland-satellite ];

      services.displayManager = {
        enable = true;
        defaultSession = "niri";

        autoLogin = {
          enable = true;
          user = "ben";
        };

        ly.enable = true;
      };

      programs.niri = {
        enable = true;
      };
    };

  flake.modules.hjem.niri =
    { pkgs, ... }:
    {
      packages = with pkgs; [
        apple-cursor
        wl-clipboard-rs

        waypipe
      ];

      rum.programs.ghostty.enable = true;

      rum.desktops.niri = {
        enable = true;

        config = builtins.readFile ./niri.kdl;

        binds =
          let
            noRepeat = {
              parameters.repeat = false;
            };
            hotkeyOverlay = title: {
              parameters.hotkey-overlay-title = title;
            };
            allowWhenLocked = {
              parameters.allow-when-locked = true;
            };
            wheelCooldown = {
              parameters.cooldown-ms = 150;
            };

            dmsIpcCall = [
              "dms"
              "ipc"
              "call"
            ];
          in
          {
            # === General ===
            # hotkeys overlay
            "Mod+Shift+Slash".action = "show-hotkey-overlay";

            # overview (zoomed-out workspace view)
            "Mod+O" = noRepeat // {
              action = "toggle-overview";
            };

            # === Programs ===
            "Mod+Return" = {
              parameters.hotkey-overlay-title = "Open Terminal";
              spawn = [ "ghostty" ];
            };
            "Mod+B" = {
              parameters.hotkey-overlay-title = "Open Brave";
              spawn = [ "brave" ];
            };
            "Mod+Space" = hotkeyOverlay "Application Launcher" // {
              spawn = dmsIpcCall ++ [
                "spotlight"
                "toggle"
              ];
            };
            "Mod+Shift+C" = hotkeyOverlay "Clipboard Manager" // {
              spawn = dmsIpcCall ++ [
                "clipboard"
                "toggle"
              ];
            };
            "Mod+M" = hotkeyOverlay "Task Manager" // {
              spawn = dmsIpcCall ++ [
                "processlist"
                "focusOrToggle"
              ];
            };
            "Ctrl+Alt+Delete" = hotkeyOverlay "Task Manager" // {
              spawn = dmsIpcCall ++ [
                "processlist"
                "focusOrToggle"
              ];
            };
            "Super+X" = hotkeyOverlay "Power Menu" // {
              spawn = dmsIpcCall ++ [
                "powermenu"
                "toggle"
              ];
            };
            "Mod+Slash" = hotkeyOverlay "Settings" // {
              spawn = dmsIpcCall ++ [
                "settings"
                "focusOrToggle"
              ];
            };
            "Mod+Y" = hotkeyOverlay "Browse Wallpapers" // {
              spawn = dmsIpcCall ++ [
                "dankdash"
                "wallpaper"
              ];
            };
            "Mod+Ctrl+N" = hotkeyOverlay "Notification Center" // {
              spawn = dmsIpcCall ++ [
                "notifications"
                "toggle"
              ];
            };

            # === Security ====
            "Mod+Ctrl+L" = hotkeyOverlay "Lock Screen" // {
              spawn = dmsIpcCall ++ [
                "lock"
                "lock"
              ];
            };
            # Quitting
            "Mod+Shift+E".action = "quit";
            "Ctrl+Alt+Escape".action = "quit";
            # Monitor Power
            "Mod+Ctrl+P".action = "power-off-monitors";

            # === Focus Movement ===
            "Mod+Left".action = "focus-column-left";
            "Mod+Down".action = "focus-window-down";
            "Mod+Up".action = "focus-window-up";
            "Mod+Right".action = "focus-column-right";
            "Mod+H".action = "focus-column-left";
            "Mod+J".action = "focus-window-down";
            "Mod+K".action = "focus-window-up";
            "Mod+L".action = "focus-column-right";

            # === Window Movement ===
            "Mod+Alt+Left".action = "move-column-left";
            "Mod+Alt+Down".action = "move-window-down";
            "Mod+Alt+Up".action = "move-window-up";
            "Mod+Alt+Right".action = "move-column-right";
            "Mod+Alt+H".action = "move-column-left";
            "Mod+Alt+J".action = "move-window-down";
            "Mod+Alt+K".action = "move-window-up";
            "Mod+Alt+L".action = "move-column-right";

            # === Jump to Column ===
            "Mod+Home".action = "focus-column-first";
            "Mod+End".action = "focus-column-last";
            "Mod+Alt+Home".action = "move-column-to-first";
            "Mod+Alt+End".action = "move-column-to-last";

            # === Focus Monitor Movement ===
            "Mod+Shift+Left".action = "focus-monitor-left";
            "Mod+Shift+Down".action = "focus-monitor-down";
            "Mod+Shift+Up".action = "focus-monitor-up";
            "Mod+Shift+Right".action = "focus-monitor-right";
            "Mod+Shift+H".action = "focus-monitor-left";
            "Mod+Shift+J".action = "focus-monitor-down";
            "Mod+Shift+K".action = "focus-monitor-up";
            "Mod+Shift+L".action = "focus-monitor-right";

            # === Move Window to Monitor ===
            "Mod+Shift+Alt+Left".action = "move-column-to-monitor-left";
            "Mod+Shift+Alt+Down".action = "move-column-to-monitor-down";
            "Mod+Shift+Alt+Up".action = "move-column-to-monitor-up";
            "Mod+Shift+Alt+Right".action = "move-column-to-monitor-right";
            "Mod+Shift+Alt+H".action = "move-column-to-monitor-left";
            "Mod+Shift+Alt+J".action = "move-column-to-monitor-down";
            "Mod+Shift+Alt+K".action = "move-column-to-monitor-up";
            "Mod+Shift+Alt+L".action = "move-column-to-monitor-right";

            # === Workspace Navigation ====
            "Mod+Page_Down".action = "focus-workspace-down";
            "Mod+Page_Up".action = "focus-workspace-up";
            "Mod+N".action = "focus-workspace-down";
            "Mod+P".action = "focus-workspace-up";
            "Mod+Alt+Page_Down".action = "move-column-to-workspace-down";
            "Mod+Alt+Page_Up".action = "move-column-to-workspace-up";
            "Mod+Alt+N".action = "move-column-to-workspace-down";
            "Mod+Alt+P".action = "move-column-to-workspace-up";

            # === Workspace Management ===
            "Ctrl+Shift+R".spawn = dmsIpcCall ++ [
              "workspace-rename"
              "open"
            ];

            # === Move Workspaces ===
            "Mod+Shift+Page_Down".action = "move-workspace-down";
            "Mod+Shift+Page_Up".action = "move-workspace-up";
            "Mod+Shift+N".action = "move-workspace-down";
            "Mod+Shift+P".action = "move-workspace-up";

            # === Mouse Wheel Navigation ===
            "Mod+WheelScrollDown" = wheelCooldown // {
              action = "focus-workspace-down";
            };
            "Mod+WheelScrollUp" = wheelCooldown // {
              action = "focus-workspace-up";
            };
            "Mod+Alt+WheelScrollDown" = wheelCooldown // {
              action = "move-column-to-workspace-down";
            };
            "Mod+Alt+WheelScrollUp" = wheelCooldown // {
              action = "move-column-to-workspace-up";
            };

            "Mod+WheelScrollRight".action = "focus-column-right";
            "Mod+WheelScrollLeft".action = "focus-column-left";
            "Mod+Alt+WheelScrollRight".action = "move-column-right";
            "Mod+Alt+WheelScrollLeft".action = "move-column-left";

            "Mod+Shift+WheelScrollDown".action = "focus-column-right";
            "Mod+Shift+WheelScrollUp".action = "focus-column-left";
            "Mod+Alt+Shift+WheelScrollDown".action = "move-column-right";
            "Mod+Alt+Shift+WheelScrollUp".action = "move-column-left";

            # === Numbered Workspaces ===
            "Mod+1".action = "focus-workspace 1";
            "Mod+2".action = "focus-workspace 2";
            "Mod+3".action = "focus-workspace 3";
            "Mod+4".action = "focus-workspace 4";
            "Mod+5".action = "focus-workspace 5";
            "Mod+6".action = "focus-workspace 6";
            "Mod+7".action = "focus-workspace 7";
            "Mod+8".action = "focus-workspace 8";
            "Mod+9".action = "focus-workspace 9";
            "Mod+0".action = "focus-workspace 10";

            "Mod+Alt+1".action = "move-column-to-workspace 1";
            "Mod+Alt+2".action = "move-column-to-workspace 2";
            "Mod+Alt+3".action = "move-column-to-workspace 3";
            "Mod+Alt+4".action = "move-column-to-workspace 4";
            "Mod+Alt+5".action = "move-column-to-workspace 5";
            "Mod+Alt+6".action = "move-column-to-workspace 6";
            "Mod+Alt+7".action = "move-column-to-workspace 7";
            "Mod+Alt+8".action = "move-column-to-workspace 8";
            "Mod+Alt+9".action = "move-column-to-workspace 9";
            "Mod+Alt+0".action = "move-column-to-workspace 10";

            "Mod+Tab".action = "focus-workspace-previous";

            # === Column Management ===
            # move window in and out of column
            "Mod+BracketLeft".action = "consume-or-expel-window-left";
            "Mod+BracketRight".action = "consume-or-expel-window-right";
            # consume one window from the right to the bottom of the focused column
            "Mod+Comma".action = "consume-window-into-column";
            # expel the bottom window from the focused column to the right
            "Mod+Period".action = "expel-window-from-column";

            # === Sizing and Layout ===
            "Mod+R".action = "switch-preset-column-width";
            "Mod+Shift+R".action = "switch-preset-column-width-back";

            "Mod+Alt+Shift+R".action = "switch-preset-window-height";
            "Mod+Alt+R".action = "reset-window-height";

            "Mod+F".action = "maximize-column";
            "Mod+Shift+F".action = "fullscreen-window";
            "Mod+Alt+F".action = "expand-column-to-available-width";

            "Mod+C".action = "center-column";
            "Mod+Alt+C".action = "center-visible-columns";

            # === Manual Sizing ===
            "Mod+Minus".action = ''set-column-width "-10%"'';
            "Mod+Equal".action = ''set-column-width "+10%"'';
            "Mod+Alt+Minus".action = ''set-window-height "-10%"'';
            "Mod+Alt+Equal".action = ''set-window-height "+10%"'';

            # === Window Management ===
            "Mod+W" = noRepeat // {
              action = "close-window";
            };
            "Mod+Shift+W" = hotkeyOverlay "Create window rule" // {
              spawn = dmsIpcCall ++ [
                "window-rules"
                "toggle"
              ];
            };

            "Mod+V".action = "toggle-window-floating";
            "Mod+Shift+V".action = "switch-focus-between-floating-and-tiling";

            "Mod+T".action = "toggle-column-tabbed-display";

            # === Screenshots ===
            "XF86Launch1".action = "screenshot";
            "Ctrl+XF86Launch1".action = "screenshot-screen";
            "Alt+XF86Launch1".action = "screenshot-window";
            "Print".action = "screenshot";
            "Ctrl+Print".action = "screenshot-screen";
            "Alt+Print".action = "screenshot-window";

            # Applications such as remote-desktop clients and software KVM switches may
            # request that niri stops processing the keyboard shortcuts defined here
            # so they may, for example, forward the key presses as-is to a remote machine.
            # It's a good idea to bind an escape hatch to toggle the inhibitor,
            # so a buggy application can't hold your session hostage.
            #
            # The allow-inhibiting=false property can be applied to other binds as well,
            # which ensures niri always processes them, even when an inhibitor is active.
            "Mod+Escape" = {
              parameters.allow-inhibiting = false;
              action = "toggle-keyboard-shortcuts-inhibit";
            };

            # === Audio Controls ===
            # Volume
            "XF86AudioRaiseVolume" = allowWhenLocked // {
              spawn = dmsIpcCall ++ [
                "audio"
                "increment"
                "3"
              ];
            };
            "XF86AudioLowerVolume" = allowWhenLocked // {
              spawn = dmsIpcCall ++ [
                "audio"
                "decrement"
                "3"
              ];
            };
            "XF86AudioMute" = allowWhenLocked // {
              spawn = dmsIpcCall ++ [
                "audio"
                "mute"
              ];
            };
            "XF86AudioMicMute" = allowWhenLocked // {
              spawn = dmsIpcCall ++ [
                "audio"
                "micmute"
              ];
            };
            # Media Control
            "XF86AudioPlay" = allowWhenLocked // {
              spawn = dmsIpcCall ++ [
                "mpris"
                "playPause"
              ];
            };
            "XF86AudioPause" = allowWhenLocked // {
              spawn = dmsIpcCall ++ [
                "mpris"
                "playPause"
              ];
            };
            "XF86AudioPrev" = allowWhenLocked // {
              spawn = dmsIpcCall ++ [
                "mpris"
                "previous"
              ];
            };
            "XF86AudioNext" = allowWhenLocked // {
              spawn = dmsIpcCall ++ [
                "mpris"
                "next"
              ];
            };
            "Ctrl+XF86AudioRaiseVolume" = allowWhenLocked // {
              spawn = dmsIpcCall ++ [
                "mpris"
                "increment"
                "3"
              ];
            };
            "Ctrl+XF86AudioLowerVolume" = allowWhenLocked // {
              spawn = dmsIpcCall ++ [
                "mpris"
                "decrement"
                "3"
              ];
            };

            # === Brightness Control ===
            "XF86MonBrightnessUp" = allowWhenLocked // {
              spawn = dmsIpcCall ++ [
                "brightness"
                "increment"
                "5"
                ""
              ];
            };
            "XF86MonBrightnessDown" = allowWhenLocked // {
              spawn = dmsIpcCall ++ [
                "brightness"
                "decrement"
                "5"
                ""
              ];
            };
          };
      };
    };
}
