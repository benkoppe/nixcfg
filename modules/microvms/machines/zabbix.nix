{ self, ... }:
let
  vHost = "zabbix.thekoppe.com";
  webPort = 8080;
in
{
  flake.clan.machines.vm-zabbix =
    { pkgs, ... }:
    {
      imports = with self.modules.nixos; [
        microvms_client
        caddy
        backup-b2
      ];

      microvm.mem = 3072;

      my.caddy.virtualHosts = [
        {
          inherit vHost;
          port = webPort;
        }
      ];

      microvm.volumes = [
        {
          image = "/tank0/microvms/zabbix/postgresql.img";
          mountPoint = "/var/lib/postgresql";
          size = 50 * 1024;
        }
        {
          image = "/tank0/microvms/zabbix/zabbix-state.img";
          mountPoint = "/var/lib/zabbix";
          size = 1 * 1024;
        }
      ];

      my.backup-b2.zabbix = {
        paths = [
          "/var/lib/postgresql"
          "/var/lib/zabbix"
        ];
        restartServices = [
          "zabbix-server"
          "phpfpm-zabbix"
          "nginx"
          "postgresql"
        ];
      };

      # https://github.com/NixOS/nixpkgs/issues/417572#issuecomment-3372914263
      services.phpfpm.pools.zabbix.phpPackage = pkgs.php83;

      services.zabbixServer = {
        enable = true;
        openFirewall = true;

        database = {
          type = "pgsql";
          createLocally = true;
        };

        settings = { };
      };

      services.zabbixWeb = {
        enable = true;
        frontend = "nginx";
        hostname = vHost;

        server.address = "127.0.0.1";

        database = {
          type = "pgsql";
        };

        nginx.virtualHost.listen = [
          {
            addr = "127.0.0.1";
            port = webPort;
          }
        ];
      };
    };
}
