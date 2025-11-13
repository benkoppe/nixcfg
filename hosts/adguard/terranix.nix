{ config, ... }:
let
  inherit (config.myTerranix) hostName;
in
{
  resource.proxmox_virtual_environment_container.${hostName} = {
    node_name = "dray";
    vm_id = 245;

    initialization.ip_config.ipv4.address = "10.192.168.245/24";
  };

  myTerranix.profiles.proxmox-lxc.enable = true;
}
