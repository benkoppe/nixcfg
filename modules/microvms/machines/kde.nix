{ self, ... }:
{
  flake.clan.machines.vm-kde =
    { pkgs, ... }:
    {
      imports = with self.modules.nixos; [
        microvms_client
      ];

      services.xserver.enable = true;
      services.displayManager.sddm.enable = true;
      services.displayManager.sddm.wayland.enable = true;
      services.desktopManager.plasma6.enable = true;
      environment.plasma6.excludePackages = with pkgs.kdePackages; [
        elisa
        khelpcenter
        krdp
      ];
    };
}
