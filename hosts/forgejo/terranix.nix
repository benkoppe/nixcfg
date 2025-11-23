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

      ldap = {
        inherit (networks.ldap) bridge deviceName;
        ipv4.address = "${networks.ldap.prefix}.${toString suffix}";
      };

      newt = {
        inherit (networks.newt) bridge deviceName;
        ipv4 = {
          inherit (networks.newt) gateway;
          address = "${networks.newt.prefix}.${toString suffix}";
        };
      };
    };
  };

  resource.proxmox_virtual_environment_container.${config.mySnippets.hostName} = {
    mount_point = {
      volume = "/tank0/files/forgejo";
      path = "/mnt/forgejo";
    };
  };
}
