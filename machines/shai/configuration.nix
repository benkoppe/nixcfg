{ self, ... }:
{
  imports = with self.modules.nixos; [
    basics
    zfs-encrypt
    network_lan
    tailgate

    ./microvms.nix
  ];

  my.tailgate.routes = [
    "10.2.0.0/24"
  ];

  services.vnstat.enable = true;

  my.networking.lan = {
    enable = true;
    interface = "eno1";
    address = "192.168.1.102";
  };
}
