{
  flake.modules.nixos."proxmox/vmbr1" = {
    services.proxmox-ve.bridges = [ "vmbr1" ];

    systemd.network.netdevs."vmbr1" = {
      netdevConfig = {
        Name = "vmbr1";
        Kind = "bridge";
      };
    };
    systemd.network.networks."vmbr1" = {
      matchConfig.Name = "vmbr1";
      networkConfig = {
        DHCPServer = true;
        IPv6SendRA = true;
      };
      addresses = [
        { addressConfig.Address = "10.0.0.1/24"; }
        { addressConfig.Address = "fd12:3456:789a::1/64"; }
      ];
      ipv6Prefixes = [
        { ipv6PrefixConfig.Prefix = "fd12:3456:789a::/64"; }
      ];
    };
    networking.nat = {
      enable = true;
      enableIPv6 = true;

      externalInterface = "enp6s0"; # uplink
      internalInterfaces = [ "vmbr1" ];
    };
  };
}
