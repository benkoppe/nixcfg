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
      enableDynamicTheming = false; # Wallpaper-based theming (matugen)
      enableAudioWavelength = true; # Audio visualizer (cava)
      enableCalendarEvents = true; # Calendar integration (khal)
      enableClipboardPaste = true; # Pasting from the clipboard history (wtype)
    };

    environment.sessionVariables = {
      QT_QPA_PLATFORMTHEME = "gtk3";
    };

    hjem.extraModules = with self.modules.hjem; [ app-icons ];
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
