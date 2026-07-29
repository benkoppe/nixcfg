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
    proxmox
  ];

  my.luks.tangUnlock.enable = false;

  my.proxmox = {
    id = 10;
    network = {
      subnet = "10.10.1";
      externalInterface = "wlp3s0";
    };
  };

  services.proxmox-ve.ipAddress = "100.95.221.58";

  my.tailgate.routes = [
    "10.10.1.0/24"
  ];

  # Use networkd only for the Proxmox virtual bridges.
  systemd.network.enable = true;
  systemd.network.networks."99-ethernet-default-dhcp".enable = false;
  systemd.network.networks."99-wireless-client-dhcp".enable = false;

  networking.networkmanager.unmanaged = [
    "interface-name:pvevirt"
    "interface-name:cluster0"
    "interface-name:tap*"
  ];

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

  # services.xserver = {
  #   enable = true;
  #   desktopManager.xfce.enable = true;
  # };
  #
  # services.displayManager.lightdm.enable = true;
}
