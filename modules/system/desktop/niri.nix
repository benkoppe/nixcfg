{ self, ... }:
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

      services.displayManager = {
        enable = true;
        defaultSession = "niri";

        autoLogin = {
          enable = true;
          user = "ben";
        };

        ly.enable = true;
      };

      programs.niri.enable = true;
    };

  flake.modules.hjem.niri = {
    imports = with self.modules.hjem; [ ghostty ];

    rum.desktops.niri = {
      enable = true;

      binds = {
        "Mod+Return" = {
          parameters.hotkey-overlay-title = "Open a Terminal: ghostty";
          spawn = [ "ghostty" ];
        };
      };
    };
  };
}
