# CHANGING this configuration requires wiping and reinstalling the machine
{ config, ... }:
{
  boot.loader.grub = {
    enable = true;
    efiSupport = true;
    efiInstallAsRemovable = true;
    enableCryptodisk = true;

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

  boot.zfs.forceImportRoot = false;
  boot.zfs.extraPools = [ "tank0" ];

  disko.devices = {
    disk =
      let
        bootDisk = idx: bootFolder: {
          type = "disk";
          device = "/dev/disk/by-id/${idx}";
          content = {
            type = "gpt";
            partitions = {
              ESP = {
                type = "EF00";
                size = "1G";
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
        mirror1 = bootDisk "nvme-Samsung_SSD_990_EVO_Plus_1TB_S7U5NJ0Y130025H" "/boot1";
        mirror2 = bootDisk "nvme-Samsung_SSD_990_EVO_Plus_1TB_S7U5NJ0Y130001T" "/boot2";

        data1 = dataDisk "nvme-INTEL_SSDPE2KX020T8_BTLJ91260J192P0BGN";
        data2 = dataDisk "nvme-INTEL_SSDPE2KX020T8_PHLJ152202EQ2P0BGN";
        data3 = dataDisk "nvme-INTEL_SSDPE2KX020T8_PHLJ152203K82P0BGN";
        data4 = dataDisk "nvme-INTEL_SSDPE2KX020T8_PHLJ152203LC2P0BGN";
      };
    zpool = {
      boot = {
        type = "zpool";
        mode = "mirror";
        options = {
          ashift = "12";
          autotrim = "on";
        };
        rootFsOptions = {
          encryption = "aes-256-gcm";
          keyformat = "passphrase";
          keylocation = "file://${config.clan.core.vars.generators.zfs-encrypt.files.password.path}";

          compression = "lz4";
          canmount = "off";
          xattr = "sa";
          acltype = "posixacl";
          "com.sun:auto-snapshot" = "false";
        };
        # FROM https://github.com/ibizaman/skarabox/blob/main/modules%2Fdisks.nix ----
        # Need to use another variable name otherwise I get SC2030 and SC2031 errors.
        preCreateHook = ''
          pname=$name
        '';
        # Needed to get back a prompt on next boot.
        # See https://github.com/nix-community/nixos-anywhere/issues/161#issuecomment-1642158475
        postCreateHook = ''
          zfs set keylocation="prompt" $pname
        '';
        # ------------
        datasets = {
          "reserved" = {
            type = "zfs_fs";
            options = {
              canmount = "off";
              mountpoint = "none";
              reservation = "50G";
            };
          };
          "local/root" = {
            type = "zfs_fs";
            options.mountpoint = "/";
            mountpoint = "/";
            postCreateHook = "zfs list -t snapshot -H -o name | grep -E '^boot/local/root@blank$' || zfs snapshot boot/local/root@blank";
          };
          "local/nix" = {
            type = "zfs_fs";
            options.mountpoint = "/nix";
            mountpoint = "/nix";
          };
          "local/tmp" = {
            type = "zfs_fs";
            mountpoint = "/tmp";
            options = {
              mountpoint = "/tmp";
              sync = "disabled";
            };
          };
          "safe/home" = {
            type = "zfs_fs";
            options.mountpoint = "/home";
            mountpoint = "/home";
          };
          "safe/persist" = {
            type = "zfs_fs";
            mountpoint = "/persist";
            # It's prefixed by /mnt because we're installing and everything is mounted under /mnt.
            options.mountpoint = "legacy";
            postMountHook = ''
              cp ${config.clan.core.vars.generators.zfs-encrypt-tank0.files.password.path} /mnt/persist/tank0-key
            '';
          };
          # README MORE: https://wiki.archlinux.org/title/ZFS#Swap_volume
          # taken from https://github.com/nix-community/disko/blob/916506443ecd0d0b4a0f4cf9d40a3c22ce39b378/example/zfs-encrypted-root.nix#L61
          "local/swap" = {
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
            };
          };
        };
      };
      tank0 = {
        type = "zpool";
        mode = "raidz2";
        options = {
          ashift = "12";
          autotrim = "on";
        };
        rootFsOptions = {
          encryption = "aes-256-gcm";
          keyformat = "passphrase";
          keylocation = "file://${config.clan.core.vars.generators.zfs-encrypt-tank0.files.password.path}";

          compression = "lz4";
          acltype = "posixacl";
          xattr = "sa";
          "com.sun:auto-snapshot" = "false";
          mountpoint = "none";
        };
        # Need to use another variable name otherwise I get SC2030 and SC2031 errors.
        preCreateHook = ''
          pname=$name
        '';
        postCreateHook = ''
          zfs set keylocation="file:///persist/tank0-key" $pname;
        '';
        datasets = {
          "reserved" = {
            type = "zfs_fs";
            options = {
              canmount = "off";
              mountpoint = "none";
              reservation = "300G";
            };
          };
          "data/files" = {
            type = "zfs_fs";
            options.mountpoint = "/tank0/files";
            mountpoint = "/tank0/files";
          };
          "data/backups" = {
            type = "zfs_fs";
            options.mountpoint = "/tank0/backups";
            mountpoint = "/tank0/backups";
          };
        };
      };
    };
  };
}
