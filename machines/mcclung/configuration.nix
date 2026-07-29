{
  self,
  lib,
  pkgs,
  config,
  ...
}:
{
  imports = with self.modules.nixos; [
    basics
    luks-encrypt
    boot_limine

    tailgate
  ];

  my.luks.tangUnlock.enable = false;

  nixpkgs.config = {
    allowUnfreePredicate =
      pkg:
      builtins.elem (lib.getName pkg) [
        "broadcom-sta"
        "facetimehd-firmware"
      ];
    allowInsecurePredicate =
      pkg:
      builtins.elem (lib.getName pkg) [
        "broadcom-sta" # aka “wl”
      ];
  };

  boot = {
    kernelPackages = pkgs.linuxPackages_6_12;
    extraModulePackages = [ config.boot.kernelPackages.broadcom_sta ];
    kernelModules = [
      "kvm-intel"
      "wl"
    ]
    ++ [
      # for tailscale and usb hotspot
      "ipheth"
      "tun"
    ];
  };

  swapDevices = [
    {
      device = "/var/lib/swapfile";
      size = 16 * 1024; # MiB
    }
  ];

  # ensure usb hotspot from iphone still works (just in case)
  services.usbmuxd.enable = true;

  environment.systemPackages = [
    pkgs.libimobiledevice
  ];

  # Let NetworkManager handle hot-plugged iPhone Ethernet interfaces.
  hardware.facter.detected.dhcp.enable = lib.mkForce false;
  networking.useDHCP = lib.mkForce false;
  networking.useNetworkd = lib.mkForce false;
  networking.networkmanager.enable = true;

  # Work around the ncurses/systemd-initrd terminfo mismatch.
  boot.initrd.systemd.contents."/etc/terminfo/l/linux".enable = false;
}
