{
  myNixOS = {
    profiles.proxmox-lxc.enable = true;
  };

  networking.hostName = "adguard";
}
