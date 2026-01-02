{ lib, ... }:
let
  maxVMs = 64;
in
{
  # guided by hhttps://microvm-nix.github.io/microvm.nix/routed-network.html
  flake.modules.nixos."microvms_host_network" = {
    networking.useNetworkd = true;

    systemd.network.networks = builtins.listToAttrs (
      map (index: {
        name = "30-vm${toString index}";
        value = {
          matchConfig.Name = "vm${toString index}";
          # Host's addresses
          address = [
            "10.0.0.0/32"
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
              Destination = "10.0.0.${toString index}/32";
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
      internalIPs = [ "10.0.0.0/24" ];
      # Change this to the interface with upstream Internet access
      externalInterface = "enp6s0";
    };
  };
}
