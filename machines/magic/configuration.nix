{ self, ... }:
{
  imports = with self.modules.nixos; [
    basics
    luks-encrypt
    boot_limine
  ];

  swapDevices = [
    {
      device = "/var/lib/swapfile";
      size = 16 * 1024; # MiB
    }
  ];
}
