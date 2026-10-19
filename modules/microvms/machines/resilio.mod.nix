{ self, ... }:
let
  storagePath = "/var/lib/resilio-sync";
in
{
  flake.clan.machines.vm-resilio =
    { config, ... }:
    {
      imports = with self.modules.nixos; [
        microvms_client

        public-endpoints_caddy
      ];

      my.public-endpoints.resilio = {
        vHost = "resilio.thekoppe.com";
        caddy.port = config.services.resilio.httpListenPort;
      };

      microvm.volumes = [
        {
          image = "/tank0/microvms/resilio/resilio-storage.img";
          mountPoint = storagePath;
          size = 512;
        }
      ];

      microvm.shares = [
        {
          proto = "virtiofs";
          tag = "resilio-files";
          source = "/tank0/files/resilio";
          mountPoint = "/mnt/files";
        }
      ];

      microvm.mem = 1024;

      services.resilio = {
        enable = true;
        enableWebUI = true;

        httpListenAddr = "0.0.0.0";
        httpListenPort = 9000;

        deviceName = "microvm-resilio";
        inherit storagePath;

        directoryRoot = "/mnt/files";
      };
    };
}
