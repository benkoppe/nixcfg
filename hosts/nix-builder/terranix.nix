{ config, ... }:
let
  inherit (config.mySnippets) networks hostName;
  inherit (config.mySnippets.hosts.${hostName}) ipv4;
in
{
  myTerranix.profiles.proxmox-vm = {
    enable = true;

    disk.size = 50;

    cpu.cores = 10;

    memory.dedicated = 32768;

    vm_id = 310;

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
