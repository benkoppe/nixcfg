{ lib, ... }:
let
  # make a two-digit string, e.g. 1 becomes "01" and 10 becomes "10"
  twoDigits =
    n:
    let
      s = builtins.toString n;
    in
    if builtins.stringLength s == 1 then "0${s}" else s;
in
{
  flake.modules.nixos."microvms_client_network" =
    { config, ... }:
    let
      cfg = config.my.microvm;
    in
    {
      options.my.microvm = {
        index = lib.mkOption {
          type = lib.types.int;
          description = "VM's unique identifier, used for networking";
        };
        ipv4 = lib.mkOption {
          type = lib.types.str;
          default = "10.0.0.${toString cfg.index}";
        };
        mac = lib.mkOption {
          type = lib.types.str;
          default = "00:00:00:00:00:${twoDigits cfg.index}";
        };
      };

      config = {
        microvm.interfaces = [
          {
            id = "vm${toString cfg.index}";
            type = "tap";
            inherit (cfg) mac;
          }
        ];

        networking.useNetworkd = true;

        systemd.network.networks."10-eth" = {
          matchConfig.MACAddress = cfg.mac;
          # Static IP configuration
          address = [
            "${cfg.ipv4}/32"
            "fec0::${lib.toHexString cfg.index}/128"
          ];
          routes = [
            {
              # A route to the host
              Destination = "10.0.0.0/32";
              GatewayOnLink = true;
            }
            {
              # Default route
              Destination = "0.0.0.0/0";
              Gateway = "10.0.0.0";
              GatewayOnLink = true;
            }
            {
              # Default route
              Destination = "::/0";
              Gateway = "fec0::";
              GatewayOnLink = true;
            }
          ];
          networkConfig = {
            # DNS servers no longer come from DHCP nor Router Advertisements.
            # Perhaps you want to change the defaults:
            DNS = [
              # Quad9.net
              "9.9.9.9"
              "149.112.112.112"
              "2620:fe::fe"
              "2620:fe::9"
            ];
          };
        };
      };
    };
}
