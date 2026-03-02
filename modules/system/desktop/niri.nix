{ inputs, ... }:
{
  flake.modules.nixos.niri =
    { pkgs, ... }:
    {
      imports = [
        inputs.niri-flake.nixosModules.niri
      ];
      nixpkgs.overlays = [
        inputs.niri-flake.overlays.niri
      ];

      programs.niri = {
        enable = true;
      };

      environment.systemPackages = with pkgs; [ alacritty ];

      # services.xserver = {
      #   enable = true;
      #   xkb.layout = "us";
      #   dpi = 220;
      #
      #   desktopManager = {
      #     xterm.enable = false;
      #     wallpaper.mode = "fill";
      #   };
      #
      #   displayManager = {
      #     lightdm.enable = true;
      #
      #     # AARCH64: For now, on Apple Silicon, we must manually set the
      #     # display resolution. This is a known issue with VMware Fusion.
      #     sessionCommands = ''
      #       ${pkgs.xorg.xset}/bin/xset r rate 200 40
      #     '';
      #   };
      #
      #   windowManager = {
      #     i3.enable = true;
      #   };
      # };
      #
      # services.displayManager = {
      #   defaultSession = "none+i3";
      # };
    };
}
