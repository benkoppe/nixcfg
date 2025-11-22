{ config, ... }:
{
  myTerranix.profiles.proxmox-lxc = {
    enable = true;

    networks =
      let
        inherit (config.mySnippets) networks hostName;
        inherit (config.mySnippets.hosts.${hostName}) ipv4 suffix;
      in
      {
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
      };
  };
}
