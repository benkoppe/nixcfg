{ self, ... }:
{
  imports = with self.modules.nixos; [
    basics
    zfs-encrypt
    tailgate
  ];
}
