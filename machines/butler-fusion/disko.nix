# ---
# schema = "ext4-single-disk"
# [placeholders]
# mainDisk = "/dev/disk/by-id/nvme-VMware_Virtual_NVMe_Disk_VMware_NVME_0000" 
# ---
# This file was automatically generated!
# CHANGING this configuration requires wiping and reinstalling the machine
{
  boot.loader.grub = {
    efiInstallAsRemovable = true;
    efiSupport = true;
  };

  disko.devices = {
    disk = {
      main = {
        name = "main-6c159f04bd1840bc99075ee996539a84";
        device = "/dev/disk/by-id/nvme-VMware_Virtual_NVMe_Disk_VMware_NVME_0000";
        type = "disk";
        content = {
          type = "gpt";
          partitions = {
            "boot" = {
              size = "1M";
              type = "EF02"; # for grub MBR
              priority = 1;
            };
            ESP = {
              type = "EF00";
              size = "500M";
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
}
