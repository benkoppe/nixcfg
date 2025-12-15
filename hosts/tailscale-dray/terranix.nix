{ config, ... }:
let
  inherit (config.mySnippets) networks hostName;
  inherit (config.mySnippets.hosts.${hostName}) ipv4;
in
{
  myTerranix.profiles.proxmox-vm = {
    enable = true;

    cloudInit = false;

    networks = {
      tailscale = {
        inherit (networks.tailscale) bridge;
        ipv4 = {
          inherit (networks.tailscale) gateway;
          address = ipv4;
        };
      };
    };
  };
}
