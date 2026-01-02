{
  flake.modules.nixos."proxmox/vmbr1" = {
    services.proxmox-ve.bridges = [ "vmbr1" ];

    systemd.network.netdevs."vmbr1".netdevConfig = {
      Kind = "bridge";
      Name = "vmbr1";
    };

    systemd.network.networks."11-lan" = {
      matchConfig.Name = "vmbr1";
      networkConfig = {
        DHCPServer = true;
        IPv6SendRA = true;
      };
      addresses = [
        {
          addressConfig.Address = "10.0.1.1/24";
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
    };

    # Allow inbound traffic for the DHCP server
    networking.firewall.allowedUDPPorts = [ 67 ];

    networking.nat = {
      enable = true;
      # NAT66 exists and works. But if you have a proper subnet in
      # 2000::/3 you should route that and remove this setting:
      enableIPv6 = true;

      # Change this to the interface with upstream Internet access
      externalInterface = "enp6s0";
      # The bridge where you want to provide Internet access
      internalInterfaces = [ "vmbr1" ];
    };
  };
}
