{ self, ... }:
{
  myNixOS = {
    profiles.proxmox-lxc.enable = true;
  };

  networking.hostName = "adguard";

  users.users.root = {
    openssh.authorizedKeys.keyFiles = [
      "${self.inputs.secrets}/pve/lxc-bootstrap-key.pub"
    ];
  };

  services.resolved.enable = false;

  services.adguardhome = {
    enable = true;
    port = 80;
    openFirewall = true;

    mutableSettings = false;
    settings = import ./adguard-conf.nix;
  };
}
