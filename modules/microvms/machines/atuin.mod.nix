{ self, ... }:
{
  flake.clan.machines.vm-atuin =
    { config, ... }:
    {
      imports = with self.modules.nixos; [
        microvms_client

        public-endpoints_caddy

        zabbix-agent-caddy
      ];

      my.public-endpoints.atuin = {
        vHost = "atuin.thekoppe.com";
        caddy.port = config.services.atuin.port;
      };

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
