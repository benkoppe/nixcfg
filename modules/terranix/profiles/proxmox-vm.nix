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
  options.myTerranix.profiles.proxmox-vm = {
    enable = lib.mkEnableOption "proxmox vm terraform defaults";

    vm_id = lib.mkOption {
      type = lib.types.int;
      description = "Proxmox VM ID";
      default = config.mySnippets.hosts.${hostName}.vm_id;
    };

    node_name = lib.mkOption {
      type = lib.types.str;
      description = "Proxmox node name for this VM";
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

    memory = rec {
      dedicated = lib.mkOption {
        type = lib.types.int;
        default = 1024;
        description = "Dedicated memory in MiB";
      };

      floating = lib.mkOption {
        type = lib.types.int;
        inherit (dedicated) default;
        description = "Floating memory in MiB";
      };
    };

    networks = lib.mkOption {
      type = lib.types.attrsOf (
        lib.types.submodule {
          options = {
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
            inherit (ts) bridge;
            ipv4 = {
              inherit (ts) gateway;
              address = config.mySnippets.hosts.${hostName}.ipv4;
            };
          };
      };
    };
  };

  config =
    let
      cfg = config.myTerranix.profiles.proxmox-vm;
    in
    lib.mkIf cfg.enable {
      myTerranix.profiles.proxmox.enable = true;

      resource.proxmox_virtual_environment_vm.${hostName} = lib.mkMerge [
        {
          description = "Managed by Terranix";
          agent.enabled = true;
          audio_device.enabled = false;
          machine = "q35";
          operating_system.type = "l26";
          migrate = true;

          inherit (cfg) vm_id node_name;

          name = hostName;

          disk = {
            datastore_id = "local-zfs";
            inherit (cfg.disk) size;
            import_from = "local:import/nixos-vm-v2.qcow2";
            interface = "scsi0";
            discard = "on";
          };

          cpu.cores = cfg.cpu.cores;

          memory = {
            inherit (cfg.memory) dedicated floating;
          };

          bios = "ovmf";
          efi_disk = {
            datastore_id = "local-zfs";
            file_format = "raw";
            type = "4m";
          };

          on_boot = true;
          tags = lib.mkDefault [ "terranix" ];

          initialization = {
            datastore_id = "local-zfs";
          };
        }
        (
          let
            inherit (cfg) networks;

            networkDeviceList = lib.mapAttrsToList (_: v: {
              inherit (v) bridge;
            }) networks;

            ipConfigList = lib.mapAttrsToList (_: v: {
              ipv4 = {
                inherit (v.ipv4) gateway;
                address = "${v.ipv4.address}/24";
              };
            }) networks;

          in
          {
            network_device = networkDeviceList;

            initialization = {
              ip_config = ipConfigList;
            };
          }
        )
      ];
    };
}
