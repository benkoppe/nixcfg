{ config, ... }:
let
  inherit (config) mySnippets;
  inherit (mySnippets) hostName;
  inherit (mySnippets.hosts.${hostName}) vm_id;
in
{
  resource.proxmox_virtual_environment_container.${hostName} = {
    node_name = "dray";
    inherit vm_id;
  };

  myTerranix.profiles.proxmox-lxc.enable = true;
}
