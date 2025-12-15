{ config, ... }:
{
  myNixOS = {
    profiles.proxmox-vm.enable = true;

    services.tailscale-server.enable = true;
  };

  networking =
    let
      inherit (config.mySnippets.networks) tailscale;
    in
    {
      hostName = "tailscale-dray";

      interfaces."eth0".ipv4.addresses = [
        {
          address = "${tailscale.prefix}.10";
          prefixLength = 24;
        }
      ];
      defaultGateway = {
        address = tailscale.gateway;
        interface = "eth0";
      };
      nameservers = [ "192.168.1.1" ];
    };
}
