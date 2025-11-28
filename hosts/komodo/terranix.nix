{ config, ... }:
{
  myTerranix.profiles.proxmox-lxc = {
    enable = true;

    networks =
      let
        inherit (config.mySnippets) networks hostName;
        inherit (config.mySnippets.hosts.${hostName}) ipv4;
      in
      {
        tailscale = {
          inherit (networks.tailscale) bridge deviceName;
          ipv4 = {
            inherit (networks.tailscale) gateway;
            address = ipv4;
          };
        };
      };

    disk.size = 20;

    cpu.cores = 4;

    memory = {
      dedicated = 8192;
      swap = 4096;
    };
  };
}
