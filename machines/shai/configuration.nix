{ self, ... }:
{
  imports = with self.modules.nixos; [
    basics
    zfs-encrypt
    tailgate

    ./microvms.nix
  ];

  my.tailgate.routes = [
    "10.2.0.0/24"
  ];
}
