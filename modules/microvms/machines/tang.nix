{ self, ... }:
{
  flake.clan.machines.vm-tang = {
    imports = with self.modules.nixos; [
      microvms_client
    ];

    microvm.volumes = [
      {
        image = "tang-data.img";
        mountPoint = "/var/lib/private/tang";
        size = 256;
      }
    ];

    networking.firewall.allowedTCPPorts = [ 80 ];

    services.tang = {
      enable = true;

      listenStream = [ "80" ];
      ipAddressAllow = [ "10.1.0.0/8" ];
    };
  };
}
