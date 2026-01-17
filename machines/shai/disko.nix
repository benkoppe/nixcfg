{ config, ... }:
{
  boot.loader.grub = {
    enable = true;
    efiSupport = true;
    efiInstallAsRemovable = true;
    enableCryptodisk = true;

    device = "nodev";
  };

  boot.zfs.forceImportRoot = false;

  boot.kernelParams = [ "zfs.zfs_arc_max=2147483648" ]; # 2 GiB

  disko.devices = {
    disk = {
      boot = {
        type = "disk";
        device = "/dev/disk/by-id/nvme-KXG50ZNV256G_NVMe_TOSHIBA_256GB_58AF726FF1WP";
        content = {
          type = "gpt";
          partitions = {
            ESP = {
              type = "EF00";
              size = "1G";
              content = {
                type = "filesystem";
                format = "vfat";
                mountpoint = "/boot";
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
    };
    zpool = {
      boot = {
        type = "zpool";
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
              reservation = "15G";
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
    };
  };
}
