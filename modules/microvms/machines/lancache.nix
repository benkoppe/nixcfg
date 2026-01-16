{ self, inputs, ... }:
{
  flake.clan.machines.vm-lancache =
    { pkgs, ... }:
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
        {
          image = "lancache-logs.img";
          mountPoint = "/var/log/nginx/lancache";
          size = 64;
        }
      ];

      services.nginx.package = pkgs.nginxMainline.override { withSlice = true; };

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
        logPrefix = "/var/log/nginx/lancache";

        upstreamDns = [ "10.1.0.1" ];
        listenAddress = "10.1.0.10";

        cacheDiskSize = "290g";
        minFreeDisk = "10g";
        cacheIndexSize = "250m";
        cacheMaxAge = "3560d";
        sliceSize = "1m";

        logFormat = "cachelog";

        domainsPackage = pkgs.fetchFromGitHub {
          owner = "uklans";
          repo = "cache-domains";
          rev = "1f5897f4dacf3dab5f4d6fca2fe497d3327eaea9";
          sha256 = "sha256-xrHuYIrGSzsPtqErREMZ8geawvtYcW6h2GyeGMw1I88=";
        };

        # Defines the number of worker processes.
        workerProcesses = "auto";
      };
    };
}
