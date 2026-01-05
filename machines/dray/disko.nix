# CHANGING this configuration requires wiping and reinstalling the machine
{ config, ... }:
{
  boot.loader.grub = {
    enable = true;
    efiSupport = true;
    efiInstallAsRemovable = true;

    mirroredBoots = [
      {
        devices = [ "nodev" ];
        path = "/boot1";
        efiSysMountPoint = "/boot1";
      }
      {
        devices = [ "nodev" ];
        path = "/boot2";
        efiSysMountPoint = "/boot2";
      }
    ];
  };

  disko.devices = {
    disk =
      let
        mirrorDisk = idx: bootFolder: {
          type = "disk";
          device = "/dev/disk/by-id/${idx}";
          content = {
            type = "gpt";
            partitions = {
              ESP = {
                type = "EF00";
                size = "500M";
                content = {
                  type = "filesystem";
                  format = "vfat";
                  mountpoint = bootFolder;
                  mountOptions = [ "umask=0077" ];
                };
              };
              zfs = {
                size = "100%";
                content = {
                  type = "zfs";
                  pool = "boot";
                };
              };
            };
          };
        };
        dataDisk = idx: {
          type = "disk";
          device = "/dev/disk/by-id/${idx}";
          content = {
            type = "gpt";
            partitions = {
              zfs = {
                size = "100%";
                content = {
                  type = "zfs";
                  pool = "tank0";
                };
              };
            };
          };
        };
      in
      {
        mirror1 = mirrorDisk "nvme-Samsung_SSD_990_EVO_Plus_1TB_S7U5NJ0Y130025H" "/boot1";
        mirror2 = mirrorDisk "nvme-Samsung_SSD_990_EVO_Plus_1TB_S7U5NJ0Y130001T" "/boot2";

        data1 = dataDisk "nvme-INTEL_SSDPE2KX020T8_BTLJ91260J192P0BGN";
        data2 = dataDisk "nvme-INTEL_SSDPE2KX020T8_PHLJ152202EQ2P0BGN";
        data3 = dataDisk "nvme-INTEL_SSDPE2KX020T8_PHLJ152203K82P0BGN";
        data4 = dataDisk "nvme-INTEL_SSDPE2KX020T8_PHLJ152203LC2P0BGN";
      };
    zpool = {
      boot = {
        type = "zpool";
        mode = "mirror";
        rootFsOptions = {
          compression = "lz4";
          acltype = "posixacl";
          xattr = "sa";
          "com.sun:auto-snapshot" = "true";
          mountpoint = "none";
        };
        options = {
          ashift = "12";
          autotrim = "on";
        };
        datasets = {
          "root" = {
            type = "zfs_fs";
            options = {
              mountpoint = "none";
              encryption = "aes-256-gcm";
              keyformat = "passphrase";
              keylocation = "file://${config.clan.core.vars.generators.zfs-encrypt.files.password.path}";
            };
          };
          "root/root" = {
            type = "zfs_fs";
            options.mountpoint = "/";
            mountpoint = "/";
          };
          "root/nix" = {
            type = "zfs_fs";
            options = {
              mountpoint = "/nix";
              "com.sun:auto-snapshot" = "false";
            };
            mountpoint = "/nix";
          };
          "root/home" = {
            type = "zfs_fs";
            options.mountpoint = "/home";
            mountpoint = "/home";
          };
          "root/tmp" = {
            type = "zfs_fs";
            mountpoint = "/tmp";
            options = {
              mountpoint = "/tmp";
              sync = "disabled";
            };
          };
          # README MORE: https://wiki.archlinux.org/title/ZFS#Swap_volume
          # taken from https://github.com/nix-community/disko/blob/916506443ecd0d0b4a0f4cf9d40a3c22ce39b378/example/zfs-encrypted-root.nix#L61
          "root/swap" = {
            type = "zfs_volume";
            size = "16G";
            content = {
              type = "swap";
            };
            options = {
              volblocksize = "4096";
              compression = "zle";
              logbias = "throughput";
              sync = "always";
              primarycache = "metadata";
              secondarycache = "none";
              "com.sun:auto-snapshot" = "false";
            };
          };
        };
      };
      tank0 = {
        type = "zpool";
        mode = "raidz2";
        rootFsOptions = {
          compression = "lz4";
          acltype = "posixacl";
          xattr = "sa";
          "com.sun:auto-snapshot" = "true";
          mountpoint = "none";
        };
        options = {
          ashift = "12";
          autotrim = "on";
        };
        datasets = {
          "root" = {
            type = "zfs_fs";
            options = {
              mountpoint = "/tank0";
              encryption = "aes-256-gcm";
              keyformat = "passphrase";
              keylocation = "file://${config.clan.core.vars.generators.zfs-encrypt.files.password.path}";
            };
            mountpoint = "/tank0";
          };
          "root/files" = {
            type = "zfs_fs";
            options.mountpoint = "/tank0/files";
            mountpoint = "/tank0/files";
          };
          "root/backups" = {
            type = "zfs_fs";
            options.mountpoint = "/tank0/backups";
            mountpoint = "/tank0/backups";
          };
        };
      };
    };
  };
}
