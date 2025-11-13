{
  config,
  lib,
  ...
}:
{
  options.myTerranix.profiles.proxmox-lxc = {
    enable = lib.mkEnableOption "proxmox lxc terraform defaults";
  };

  config = lib.mkIf config.myTerranix.profiles.proxmox-lxc.enable (
    let
      inherit (config.myTerranix)
        hostName
        ;
    in
    {
      myTerranix.profiles.proxmox.enable = true;

      resource.proxmox_virtual_environment_container.${hostName} = {
        description = "Managed by Terranix";
        unprivileged = lib.mkDefault true;

        network_interface = {
          name = "eth_ts";
          bridge = "vxnetts";
        };

        disk = {
          datastore_id = "local-zfs";
          size = 10;
        };

        cpu.cores = 2;

        memory = {
          dedicated = 1024;
          swap = 512;
        };

        operating_system = {
          template_file_id = "local:vztmpl/nixos-flake-bootstrap-x86_64-linux.tar.xz";
          type = "nixos";
        };

        initialization = {
          hostname = hostName;
          ip_config.ipv4.gateway = "10.192.168.1";
        };

        features = {
          nesting = true;
        };

        start_on_boot = true;
        tags = lib.mkDefault [ "terranix" ];
      };
    }
  );
}
