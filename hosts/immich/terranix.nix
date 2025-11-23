{ config, ... }:
let
  inherit (config.mySnippets) networks hostName;
  inherit (config.mySnippets.hosts.${hostName}) ipv4;
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
    };

    cpu.cores = 4;

    memory = {
      dedicated = 8192;
      swap = 2048;
    };
  };

  resource.proxmox_virtual_environment_container.${config.mySnippets.hostName} = {
    mount_point = {
      volume = "/tank0/files/immich";
      path = "/mnt/immich";
    };

    device_passthrough = {
      path = "/dev/dri/card0";
    };
  };
}
