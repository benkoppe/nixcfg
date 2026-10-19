{
  flake.modules.nixos.network_lan =
    { config, lib, ... }:
    let
      cfg = config.my.networking.lan;
    in
    {
      options.my.networking.lan = {
        enable = lib.mkEnableOption "static host LAN networking";

        interface = lib.mkOption {
          type = lib.types.str;
        };

        address = lib.mkOption {
          type = lib.types.str;
        };

        prefixLength = lib.mkOption {
          type = lib.types.int;
          default = 24;
        };

        gateway = lib.mkOption {
          type = lib.types.str;
          default = "192.168.1.1";
        };

        dns = lib.mkOption {
          type = lib.types.listOf lib.types.str;
          default = [ "192.168.1.1" ];
        };
      };

      config = lib.mkIf cfg.enable {
        networking.useNetworkd = true;

        systemd.network.networks."10-lan" = {
          matchConfig.Name = cfg.interface;
          address = [ "${cfg.address}/${toString cfg.prefixLength}" ];
          networkConfig.Gateway = cfg.gateway;
          inherit (cfg) dns;
        };
      };
    };
}
