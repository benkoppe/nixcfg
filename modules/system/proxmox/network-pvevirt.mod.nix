{ lib, ... }:
{
  flake.modules.nixos."proxmox/network-pvevirt" =
    { config, ... }:
    let
      cfg = config.my.proxmox.network;
    in
    {
      options.my.proxmox.network = {
        subnet = lib.mkOption {
          type = lib.types.str;
          description = "Subnet for the microvm network, i.e. 10.0.0";
          default = "10.0.1";
        };
        gateway = lib.mkOption {
          type = lib.types.str;
          description = "Gateway for the microvm network, i.e. 10.0.0.0";
          default = "${cfg.subnet}.1";
        };
        externalInterface = lib.mkOption {
          type = lib.types.str;
          description = "External network interface for NAT";
          default = "enp6s0";
        };
      };

      config = {
        topology.networks."${config.networking.hostName}-pvevirt" = {
          name = "${config.networking.hostName} Proxmox guests";
          cidrv4 = "${cfg.subnet}.0/24";
          cidrv6 = "fd12:4567:789a::/64";
        };

        topology.self.interfaces.pvevirt = {
          virtual = true;
          type = "bridge";
          addresses = [
            cfg.gateway
            "fd12:4567:789a::1"
          ];
          network = "${config.networking.hostName}-pvevirt";
        };

        services.proxmox-ve.bridges = [ "pvevirt" ];

        systemd.network.netdevs."pvevirt".netdevConfig = {
          Kind = "bridge";
          Name = "pvevirt";
        };

        systemd.network.networks."11-lan" = {
          matchConfig.Name = "pvevirt";
          networkConfig = {
            DHCPServer = true;
            IPv6SendRA = true;
          };
          addresses = [
            {
              addressConfig.Address = "${cfg.gateway}/24";
            }
            {
              addressConfig.Address = "fd12:4567:789a::1/64";
            }
          ];
          ipv6Prefixes = [
            {
              ipv6PrefixConfig.Prefix = "fd12:4567:789a::/64";
            }
          ];
          # Enable routing
          networkConfig = {
            IPv4Forwarding = true;
            IPv6Forwarding = true;
          };
        };

        # Allow inbound traffic for the DHCP server
        networking.firewall.allowedUDPPorts = [ 67 ];

        networking.nat = {
          enable = true;
          # NAT66 exists and works. But if you have a proper subnet in
          # 2000::/3 you should route that and remove this setting:
          enableIPv6 = true;

          inherit (cfg) externalInterface; # upstream
          internalInterfaces = [ "pvevirt" ]; # downstream
        };
      };
    };
}
