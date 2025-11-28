{
  myNixOS = {
    profiles.proxmox-lxc.enable = true;
  };

  networking.hostName = "adguard";

  services.resolved.enable = false;

  services.adguardhome = {
    enable = true;
    port = 80;
    openFirewall = true;

    mutableSettings = false;
    settings = import ./adguard-conf.nix;
  };
}
