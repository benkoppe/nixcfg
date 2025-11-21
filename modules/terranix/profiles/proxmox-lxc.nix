{
  config,
  lib,
  ...
}:
{
  options.myTerranix.profiles.proxmox-lxc = {
    enable = lib.mkEnableOption "proxmox lxc terraform defaults";

    disk.size = lib.mkOption {
      type = lib.types.int;
      default = 10;
      description = "Disk size in GB";
    };

    cpu.cores = lib.mkOption {
      type = lib.types.int;
      default = 2;
      description = "Num. CPU cores";
    };

    memory = {
      dedicated = lib.mkOption {
        type = lib.types.int;
        default = 1024;
        description = "Dedicated memory in MiB";
      };

      swap = lib.mkOption {
        type = lib.types.int;
        default = 512;
        description = "Swap memory in MiB";
      };
    };

  };

  config = lib.mkIf config.myTerranix.profiles.proxmox-lxc.enable (
    let
      inherit (config.mySnippets)
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
          inherit (config.myTerranix.profiles.proxmox-lxc.disk) size;
        };

        cpu.cores = config.myTerranix.profiles.proxmox-lxc.cpu.cores;

        memory = {
          inherit (config.myTerranix.profiles.proxmox-lxc.memory) dedicated swap;
        };

        operating_system = {
          template_file_id = "local:vztmpl/nixos-flake-bootstrap-x86_64-linux.tar.xz";
          type = "nixos";
        };

        initialization = {
          hostname = hostName;
          ip_config.ipv4.gateway = "${config.mySnippets.networks.tailscale.gateway}";
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
