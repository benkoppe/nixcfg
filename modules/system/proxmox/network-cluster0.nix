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
