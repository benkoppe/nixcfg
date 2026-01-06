{ lib, ... }:
let
  maxVMs = 64;
in
{
  # guided by hhttps://microvm-nix.github.io/microvm.nix/routed-network.html
  flake.modules.nixos."microvms_host_network" =
    { config, ... }:
    let
      cfg = config.my.microvms.network;
    in
    {
      options.my.microvms.network = {
        subnet = lib.mkOption {
          type = lib.types.str;
          description = "Subnet for the microvm network, i.e. 10.0.0";
          default = "10.0.0";
        };
        gateway = lib.mkOption {
          type = lib.types.str;
          description = "Gateway for the microvm network, i.e. 10.0.0.0";
          default = "${cfg.subnet}.0";
        };
        externalInterface = lib.mkOption {
          type = lib.types.str;
          description = "External network interface for NAT";
          default = "enp6s0";
        };
      };

      config = {
        networking.useNetworkd = true;

        systemd.network.networks = builtins.listToAttrs (
          map (index: {
            name = "30-vm${toString index}";
            value = {
              matchConfig.Name = "vm${toString index}";
              # Host's addresses
              address = [
                "${cfg.gateway}/32"
                "fec0::/128"
              ];
              # Setup routes to the VM
              routes = [
                {
                  # Route to legacy tailscale subnet
                  Destination = "10.192.168.0/24";
                  Gateway = "10.0.0.2";
                }
                {
                  Destination = "${cfg.subnet}.${toString index}/32";
                }
                {
                  Destination = "fec0::${lib.toHexString index}/128";
                }
              ];
              # Enable routing
              networkConfig = {
                IPv4Forwarding = true;
                IPv6Forwarding = true;
              };
            };
          }) (lib.genList (i: i + 1) maxVMs)
        );

        networking.nat = {
          enable = true;
          internalIPs = [ "${cfg.subnet}.0/24" ];
          # Change this to the interface with upstream Internet access
          inherit (cfg) externalInterface;
        };
      };
    };
}
