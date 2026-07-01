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

  # Work around a nixpkgs/systemd-initrd mismatch: config/terminfo.nix
  # adds /etc/terminfo/l/linux from pkgs.ncurses, but this ncurses build
  # does not ship share/terminfo/l/linux, causing initrd assembly to fail.
  boot.initrd.systemd.contents."/etc/terminfo/l/linux".enable = false;
}
