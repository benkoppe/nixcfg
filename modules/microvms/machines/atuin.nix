{ self, ... }:
let
  vHost = "atuin.thekoppe.com";
in
{
  flake.clan.machines.vm-atuin =
    { config, ... }:
    {
      imports = with self.modules.nixos; [
        microvms_client
        caddy
      ];

      my.caddy.virtualHosts = [
        {
          inherit vHost;
          inherit (config.services.atuin) port;
        }
      ];

      microvm.volumes = [
        {
          image = "atuin-postgresql.img";
          mountPoint = "/var/lib/postgresql";
          size = 10 * 1024;
        }
      ];

      services.atuin = {
        enable = true;

        port = 8888;
        openRegistration = false;

        database.createLocally = true;
      };
    };
}
