{ config, ... }:
let
  inherit (config.mySnippets) networks hostName;
  inherit (config.mySnippets.hosts.${hostName}) ipv4 suffix;
in
{
  myTerranix.profiles.proxmox-lxc = {
    enable = true;

    networks = {
      tailscale = {
        inherit (networks.tailscale) bridge deviceName;
        ipv4 = {
          inherit (networks.tailscale) gateway;
          address = ipv4;
        };
      };

      obs = {
        inherit (networks.obs) bridge deviceName;
        ipv4 = {
          address = "${networks.obs.prefix}.${toString suffix}";
        };
      };
    };
  };
}
