{ self, inputs, ... }:
{
  flake.clan.machines.vm-lancache =
    { ... }:
    {
      imports = with self.modules.nixos; [
        microvms_client

        inputs.lancache-nix.nixosModules.default
      ];

      microvm.volumes = [
        {
          image = "/tank0/microvms/lancache/lancache-data.img";
          mountPoint = "/var/lib/lancache";
          size = 300 * 1024;
        }
      ];

      services.resolved.enable = false;

      networking.firewall = {
        allowedTCPPorts = [
          53
          80
          443
        ];
        allowedUDPPorts = [ 53 ];
      };

      microvm.mem = 4096;

      services.lancache = {
        enable = true;

        cacheLocation = "/var/lib/lancache/cache";
        listenAddress = "10.1.0.10";

        cacheDiskSize = "290g";
        cacheIndexSize = "250m";
      };
    };
}
