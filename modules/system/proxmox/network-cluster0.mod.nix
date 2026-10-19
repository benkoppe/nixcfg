{ lib, ... }:
{
  flake.modules.nixos."proxmox/network-cluster0" =
    { config, ... }:
    let
      cfg = config.my.proxmox;
    in
    {
      options.my.proxmox.id = lib.mkOption {
        type = lib.types.int;
        description = "Unique host ID for the cluster network";
      };

      config = {
        topology.networks.proxmox-cluster = {
          name = lib.mkDefault "Proxmox cluster";
          cidrv4 = lib.mkDefault "10.201.201.0/24";
        };

        topology.self.interfaces.cluster0 = {
          virtual = true;
          type = "bridge";
          addresses = [ "10.201.201.${toString cfg.id}" ];
          network = "proxmox-cluster";
        };

        services.proxmox-ve.bridges = [ "cluster0" ];

        systemd.network.netdevs."cluster0" = {
          netdevConfig = {
            Name = "cluster0";
            Kind = "bridge";
          };
        };

        systemd.network.networks."30-cluster" = {
          matchConfig.Name = "cluster0";
          networkConfig = {
            ConfigureWithoutCarrier = true;
            IPv6AcceptRA = false;
            DHCPServer = false;
          };
          addresses = [
            {
              addressConfig.Address = "10.201.201.${toString cfg.id}/24"; # unique per host
            }
          ];
        };
      };
    };
}
