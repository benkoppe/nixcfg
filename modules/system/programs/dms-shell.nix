{ self, ... }:
{
  flake.modules.nixos.dms-shell = {
    programs.dms-shell = {
      enable = true;

      systemd = {
        enable = true;
        restartIfChanged = true;
      };

      # Core features
      enableSystemMonitoring = true; # System monitoring widgets (dgop)
      enableVPN = true; # VPN management widget
      enableDynamicTheming = true; # Wallpaper-based theming (matugen)
      enableAudioWavelength = true; # Audio visualizer (cava)
      enableCalendarEvents = true; # Calendar integration (khal)
      enableClipboardPaste = true; # Pasting from the clipboard history (wtype)
    };

    environment.sessionVariables = {
      QT_QPA_PLATFORMTHEME = "gtk3";
    };

    hjem.extraModules = with self.modules.hjem; [
      dms-shell-theming
      app-icons
    ];
  };

  flake.modules.hjem.dms-shell-theming =
    { lib, ... }:
    {
      rum.desktops.niri.config =
        lib.mkAfter # kdl
          ''
            // Include dms files
            include "dms/colors.kdl"
            include "dms/layout.kdl"
            include "dms/alttab.kdl"
            include "dms/outputs.kdl"
            include "dms/cursor.kdl"
          '';

      # disable niri config validation
      rum.desktops.niri.package = lib.mkForce null;

      rum.programs.ghostty.settings = {
        theme = lib.mkForce "dankcolors";
      };
    };

  # use with dms-shell to provide app icons
  flake.modules.hjem.app-icons =
    { pkgs, ... }:
    {
      packages = with pkgs; [
        kdePackages.breeze-icons
        hicolor-icon-theme
      ];

      xdg.config.files."gtk-3.0/settings.ini".text = ''
        [Settings]
        gtk-icon-theme-name=breeze-dark
      '';
    };
}
