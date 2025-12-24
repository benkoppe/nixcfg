# ---
# schema = "single-disk"
# [placeholders]
# mainDisk = "/dev/disk/by-id/nvme-Samsung_SSD_990_PRO_with_Heatsink_2TB_S7DRNJ0Y103229H"
# ---
# This file was automatically generated!
# CHANGING this configuration requires wiping and reinstalling the machine
{ config, ... }:
{
  boot.loader.grub.efiSupport = true;
  boot.loader.grub.efiInstallAsRemovable = true;
  boot.loader.grub.enable = true;
  disko.devices = {
    disk = {
      main = {
        name = "main-2fcc4c4672084f85aad0e4eb8a4c8472";
        device = "/dev/disk/by-id/nvme-Samsung_SSD_990_PRO_with_Heatsink_2TB_S7DRNJ0Y103229H";
        type = "disk";
        content = {
          type = "gpt";
          partitions = {
            ESP = {
              size = "1G";
              type = "EF00";
              content = {
                type = "filesystem";
                format = "vfat";
                mountpoint = "/boot";
                mountOptions = [ "umask=0077" ];
              };
            };
            root = {
              size = "100%";
              content = {
                type = "luks";
                name = "crypted";
                passwordFile = config.clan.core.vars.generators.luks-password.files.password.path;
                settings = {
                  allowDiscards = true;
                };
                content = {
                  type = "filesystem";
                  format = "ext4";
                  mountpoint = "/";
                };
              };
            };
          };
        };
      };
    };
  };
}
