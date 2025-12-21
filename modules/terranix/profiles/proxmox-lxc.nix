{
  config,
  lib,
  ...
}:
let
  inherit (config.mySnippets)
    hostName
    ;
in
{
  options.myTerranix.profiles.proxmox-lxc = {
    enable = lib.mkEnableOption "proxmox lxc terraform defaults";

    vm_id = lib.mkOption {
      type = lib.types.int;
      description = "Proxmox VM ID";
      default = config.mySnippets.hosts.${hostName}.vm_id;
    };

    node_name = lib.mkOption {
      type = lib.types.str;
      description = "Proxmox node name for this CT";
      default = "dray";
    };

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

    networks = lib.mkOption {
      type = lib.types.attrsOf (
        lib.types.submodule {
          options = {
            deviceName = lib.mkOption {
              type = lib.types.str;
              description = "Interface name (e.g. eth0)";
            };
            bridge = lib.mkOption {
              type = lib.types.str;
              description = "Bridge to attach to";
            };

            ipv4.address = lib.mkOption {
              type = lib.types.str;
              description = "IPv4 CIDR address";
            };

            ipv4.gateway = lib.mkOption {
              type = lib.types.nullOr lib.types.str;
              default = null;
              description = "Gateway (optional)";
            };
          };
        }
      );
      description = "Network interface definitions";
      default = {
        tailscale =
          let
            ts = config.mySnippets.networks.tailscale;
          in
          {
            inherit (ts) bridge deviceName;
            ipv4 = {
              inherit (ts) gateway;
              address = config.mySnippets.hosts.${hostName}.ipv4;
            };
          };
      };
    };
  };

  config = lib.mkIf config.myTerranix.profiles.proxmox-lxc.enable {
    myTerranix.providers.proxmox.enable = true;

    resource.proxmox_virtual_environment_container.${hostName} = {
      description = "Managed by Terranix";
      unprivileged = lib.mkDefault true;

      inherit (config.myTerranix.profiles.proxmox-lxc) vm_id node_name;

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

      features = {
        nesting = true;
      };

      start_on_boot = true;
      tags = lib.mkDefault [ "terranix" ];
    }
    // (
      let
        inherit (config.myTerranix.profiles.proxmox-lxc) networks;

        networkInterfaceList = lib.mapAttrsToList (_: v: {
          inherit (v) bridge;
          name = v.deviceName;
        }) networks;

        ipConfigList = lib.mapAttrsToList (_: v: {
          ipv4 = {
            inherit (v.ipv4) gateway;
            address = "${v.ipv4.address}/24";
          };
        }) networks;
      in
      {
        network_interface = networkInterfaceList;
        initialization = {
          hostname = hostName;
          ip_config = ipConfigList;
        };
      }
    );
  };
}
