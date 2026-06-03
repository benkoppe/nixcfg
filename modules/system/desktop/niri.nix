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

      environment.systemPackages = with pkgs; [ alacritty ];

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
}
