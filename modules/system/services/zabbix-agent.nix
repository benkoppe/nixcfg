_: {
  flake.modules.nixos.zabbix-agent =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    {
      options.my.zabbix-agent = {
        server = lib.mkOption {
          type = lib.types.str;
          default = "10.1.0.13";
          description = "The address of the Zabbix server";
        };
      };

      config.services.zabbixAgent =
        let
          serverIP = config.my.zabbix-agent.server;
        in
        {
          enable = true;
          openFirewall = true;
          server = serverIP;

          extraPackages = with pkgs; [ systemd ];

          settings = {
            Hostname = lib.mkDefault config.networking.hostName;

            ServerActive = serverIP;

            UserParameter = [
              "systemd.unit.active[*],systemctl is-active --quiet $1 && echo 1 || echo 0"
            ];
          };
        };
    };
}
