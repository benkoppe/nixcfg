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
    { config, hostConfig, ... }:
    let
      cfg = config.my.microvm;
      inherit (hostConfig.my.microvms) network;
    in
    {
      options.my.microvm = {
        ipv4 = lib.mkOption {
          type = lib.types.str;
          default = "${network.subnet}.${toString cfg.id}";
        };
        mac = lib.mkOption {
          type = lib.types.str;
          default = "00:00:00:00:00:${twoDigits cfg.id}";
        };
      };

      config = {
        microvm.interfaces = [
          {
            id = "vm${toString cfg.id}";
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
            "fec0::${lib.toHexString cfg.id}/128"
          ];
          routes = [
            {
              # A route to the host
              Destination = "${network.gateway}/32";
              GatewayOnLink = true;
            }
            {
              # Default route
              Destination = "0.0.0.0/0";
              Gateway = "${network.gateway}";
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
            DNS = [
              "192.168.1.1"
            ];
          };
        };
      };
    };
}
