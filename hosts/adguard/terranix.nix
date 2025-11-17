{ config, ... }:
let
  inherit (config.myTerranix) hostName;
  inherit (config) mySnippets;
  inherit (mySnippets.hosts.${hostName}) vm_id;
  inherit (mySnippets.networks) tailscale;
in
{
  resource.proxmox_virtual_environment_container.${hostName} = {
    node_name = "dray";
    inherit vm_id;

    initialization.ip_config.ipv4.address = "${tailscale.prefix}.${toString vm_id}/24";
  };

  myTerranix.profiles.proxmox-lxc.enable = true;
}
