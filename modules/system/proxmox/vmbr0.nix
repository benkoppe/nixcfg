{
  flake.modules.nixos."proxmox/vmbr0" = {
    services.proxmox-ve.bridges = [ "vmbr0" ];

    systemd.network.networks."10-lan" = {
      matchConfig.Name = [ "enp6s0" ];
      networkConfig = {
        Bridge = "vmbr0";
      };
    };

    systemd.network.netdevs."vmbr0" = {
      netdevConfig = {
        Name = "vmbr0";
        Kind = "bridge";
      };
    };

    systemd.network.networks."10-lan-bridge" = {
      matchConfig.Name = "vmbr0";
      networkConfig = {
        IPv6AcceptRA = true;
        DHCP = "ipv4";
      };
      linkConfig.RequiredForOnline = "routable";
    };
  };
}
