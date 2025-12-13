{ config, ... }:
let
  inherit (config.mySnippets) networks hostName;
  inherit (config.mySnippets.hosts.${hostName}) ipv4 suffix;
in
{
  myTerranix.profiles.proxmox-lxc = {
    enable = true;

    networks = {
      cloudflare = {
        inherit (networks.cloudflare) bridge deviceName;
        ipv4 = {
          inherit (networks.cloudflare) gateway;
          address = ipv4;
        };
      };

      tailscale = {
        inherit (networks.tailscale) bridge deviceName;
        ipv4 = {
          inherit (networks.tailscale) gateway;
          address = "${networks.tailscale.prefix}.${toString suffix}";
        };
      };
    };
  };
}
