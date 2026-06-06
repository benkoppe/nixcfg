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
            allowWhenLocked = {
              parameters.allow-when-locked = true;
            };
            wheelCooldown = {
              parameters.cooldown-ms = 150;
            };
          in
          {
            # # GENERAL
            # # hotkeys overlay
            # "Mod+Shift+Slash".action = "show-hotkey-overlay";
            #
            # # overview (zoomed-out workspace view)
            # "Mod+O" = {
            #   parameters.repeat = false;
            #   action = "toggle-overview";
            # };
            #
            # # close window
            # "Mod+W" = {
            #   parameters.repeat = false;
            #   action = "close-window";
            # };
            #
            # # PROGRAMS
            # # "Super+Alt+L" = {
            # #   parameters.hotkey-overlay-title = "Lock Screen";
            # #   spawn = [ "hyprlock" ];
            # # };
            # "Mod+Return" = {
            #   parameters.hotkey-overlay-title = "Open Terminal";
            #   spawn = [ "ghostty" ];
            # };
            # "Mod+B" = {
            #   parameters.hotkey-overlay-title = "Open Brave";
            #   spawn = [ "brave" ];
            # };
            #
            # # MOVEMENT
            # "Mod+Left".action = "focus-column-left";
            # "Mod+Down".action = "focus-window-down";
            # "Mod+Up".action = "focus-window-up";
            # "Mod+Right".action = "focus-column-right";
            # "Mod+H".action = "focus-column-left";
            # "Mod+J".action = "focus-window-down";
            # "Mod+K".action = "focus-window-up";
            # "Mod+L".action = "focus-column-right";
            #
            # "Mod+Ctrl+Left".action = "move-column-left";
            # "Mod+Ctrl+Down".action = "move-window-down";
            # "Mod+Ctrl+Up".action = "move-window-up";
            # "Mod+Ctrl+Right".action = "move-column-right";
            # "Mod+Ctrl+H".action = "move-column-left";
            # "Mod+Ctrl+J".action = "move-window-down";
            # "Mod+Ctrl+K".action = "move-window-up";
            # "Mod+Ctrl+L".action = "move-column-right";
            #
            # "Mod+Home".action = "focus-column-first";
            # "Mod+End".action = "focus-column-last";
            # "Mod+Ctrl+Home".action = "move-column-to-first";
            # "Mod+Ctrl+End".action = "move-column-to-last";
            #
            # "Mod+Shift+Left".action = "focus-monitor-left";
            # "Mod+Shift+Down".action = "focus-monitor-down";
            # "Mod+Shift+Up".action = "focus-monitor-up";
            # "Mod+Shift+Right".action = "focus-monitor-right";
            # "Mod+Shift+H".action = "focus-monitor-left";
            # "Mod+Shift+J".action = "focus-monitor-down";
            # "Mod+Shift+K".action = "focus-monitor-up";
            # "Mod+Shift+L".action = "focus-monitor-right";
            #
            # "Mod+Shift+Ctrl+Left".action = "move-column-to-monitor-left";
            # "Mod+Shift+Ctrl+Down".action = "move-column-to-monitor-down";
            # "Mod+Shift+Ctrl+Up".action = "move-column-to-monitor-up";
            # "Mod+Shift+Ctrl+Right".action = "move-column-to-monitor-right";
            # "Mod+Shift+Ctrl+H".action = "move-column-to-monitor-left";
            # "Mod+Shift+Ctrl+J".action = "move-column-to-monitor-down";
            # "Mod+Shift+Ctrl+K".action = "move-column-to-monitor-up";
            # "Mod+Shift+Ctrl+L".action = "move-column-to-monitor-right";
            #
            # "Mod+Page_Down".action = "focus-workspace-down";
            # "Mod+Page_Up".action = "focus-workspace-up";
            # "Mod+N".action = "focus-workspace-down";
            # "Mod+P".action = "focus-workspace-up";
            #
            # "Mod+WheelScrollDown" = wheelCooldown // {
            #   action = "focus-workspace-down";
            # };
            # "Mod+WheelScrollUp" = wheelCooldown // {
            #   action = "focus-workspace-up";
            # };
            # "Mod+Ctrl+WheelScrollDown" = wheelCooldown // {
            #   action = "move-column-to-workspace-down";
            # };
            # "Mod+Ctrl+WheelScrollUp" = wheelCooldown // {
            #   action = "move-column-to-workspace-up";
            # };
            #
            # "Mod+WheelScrollRight".action = "focus-column-right";
            # "Mod+WheelScrollLeft".action = "focus-column-left";
            # "Mod+Shift+WheelScrollDown".action = "focus-column-right";
            # "Mod+Shift+WheelScrollUp".action = "focus-column-left";
            # "Mod+Ctrl+WheelScrollRight".action = "move-column-right";
            # "Mod+Ctrl+WheelScrollLeft".action = "move-column-left";
            # "Mod+Ctrl+Shift+WheelScrollDown".action = "move-column-right";
            # "Mod+Ctrl+Shift+WheelScrollUp".action = "move-column-left";
            #
            # "Mod+1".action = "focus-workspace 1";
            # "Mod+2".action = "focus-workspace 2";
            # "Mod+3".action = "focus-workspace 3";
            # "Mod+4".action = "focus-workspace 4";
            # "Mod+5".action = "focus-workspace 5";
            # "Mod+6".action = "focus-workspace 6";
            # "Mod+7".action = "focus-workspace 7";
            # "Mod+8".action = "focus-workspace 8";
            # "Mod+9".action = "focus-workspace 9";
            # "Mod+0".action = "focus-workspace 10";
            # "Mod+Ctrl+1".action = "move-column-to-workspace 1";
            # "Mod+Ctrl+2".action = "move-column-to-workspace 2";
            # "Mod+Ctrl+3".action = "move-column-to-workspace 3";
            # "Mod+Ctrl+4".action = "move-column-to-workspace 4";
            # "Mod+Ctrl+5".action = "move-column-to-workspace 5";
            # "Mod+Ctrl+6".action = "move-column-to-workspace 6";
            # "Mod+Ctrl+7".action = "move-column-to-workspace 7";
            # "Mod+Ctrl+8".action = "move-column-to-workspace 8";
            # "Mod+Ctrl+9".action = "move-column-to-workspace 9";
            # "Mod+Ctrl+0".action = "move-column-to-workspace 10";
            #
            # "Mod+Tab".action = "focus-workspace-previous";
            #
            # # move window in and out of column
            # "Mod+BracketLeft".action = "consume-or-expel-window-left";
            # "Mod+BracketRight".action = "consume-or-expel-window-right";
            #
            # # consume one window from the right to the bottom of the focused column
            # "Mod+Comma".action = "consume-window-into-column";
            # # expel the bottom window from the focused column to the right
            # "Mod+Period".action = "expel-window-from-column";
            #
            # "Mod+R".action = "switch-preset-column-width";
            # "Mod+Shift+R".action = "switch-preset-column-width-back";
            #
            # "Mod+Ctrl+Shift+R".action = "switch-preset-window-height";
            # "Mod+Ctrl+R".action = "reset-window-height";
            #
            # "Mod+F".action = "maximize-column";
            # "Mod+Shift+F".action = "fullscreen-window";
            #
            # "Mod+Ctrl+F".action = "expand-column-to-available-width";
            #
            # "Mod+C".action = "center-column";
            # "Mod+Shift+C".action = "center-visible-columns";
            #
            # "Mod+Minus".action = ''set-column-width "-10%"'';
            # "Mod+Equal".action = ''set-column-width "+10%"'';
            #
            # "Mod+Shift+Minus".action = ''set-window-height "-10%"'';
            # "Mod+Shift+Equal".action = ''set-window-height "+10%"'';
            #
            # "Mod+V".action = "toggle-window-floating";
            # "Mod+Shift+V".action = "switch-focus-between-floating-and-tiling";
            #
            # "Mod+T".action = "toggle-column-tabbed-display";
            #
            # # Printing
            # "Print".action = "screenshot";
            # "Ctrl+Print".action = "screenshot-screen";
            # "Alt+Print".action = "screenshot-window";
            #
            # # Applications such as remote-desktop clients and software KVM switches may
            # # request that niri stops processing the keyboard shortcuts defined here
            # # so they may, for example, forward the key presses as-is to a remote machine.
            # # It's a good idea to bind an escape hatch to toggle the inhibitor,
            # # so a buggy application can't hold your session hostage.
            # #
            # # The allow-inhibiting=false property can be applied to other binds as well,
            # # which ensures niri always processes them, even when an inhibitor is active.
            # "Mod+Escape" = {
            #   parameters.allow-inhibiting = false;
            #   action = "toggle-keyboard-shortcuts-inhibit";
            # };
            #
            # # Quitting
            # "Mod+Shift+E".action = "quit";
            # "Ctrl+Alt+Delete".action = "quit";
            #
            # "Mod+Shift+P".action = "power-off-monitors";
            #
            # # VOLUME
            # "XF86AudioRaiseVolume" = allowWhenLocked // {
            #   action = ''spawn-sh "wpctl set-volume @DEFAULT_AUDIO_SINK@ 0.1+ -l 1.0"'';
            # };
            # "XF86AudioLowerVolume" = allowWhenLocked // {
            #   action = ''spawn-sh "wpctl set-volume @DEFAULT_AUDIO_SINK@ 0.1-"'';
            # };
            # "XF86AudioMute" = allowWhenLocked // {
            #   action = ''spawn-sh "wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"'';
            # };
            # "XF86AudioMicMute" = allowWhenLocked // {
            #   action = ''spawn-sh "wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"'';
            # };
            #
            # # MEDIA CONTROL
            # "XF86AudioPlay" = allowWhenLocked // {
            #   action = ''spawn-sh "playerctl play-pause"'';
            # };
            # "XF86AudioStop" = allowWhenLocked // {
            #   action = ''spawn-sh "playerctl stop"'';
            # };
            # "XF86AudioPrev" = allowWhenLocked // {
            #   action = ''spawn-sh "playerctl previous"'';
            # };
            # "XF86AudioNext" = allowWhenLocked // {
            #   action = ''spawn-sh "playerctl next"'';
            # };
            #
            # # BRIGHTNESS
            # "XF86MonBrightnessUp" = allowWhenLocked // {
            #   spawn = [
            #     "brightnessctl"
            #     "--class=backlight"
            #     "set"
            #     "+10%"
            #   ];
            # };
            # "XF86MonBrightnessDown" = allowWhenLocked // {
            #   spawn = [
            #     "brightnessctl"
            #     "--class=backlight"
            #     "set"
            #     "10%-"
            #   ];
            # };
          };
      };
    };
}
