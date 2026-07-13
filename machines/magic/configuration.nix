{
  self,
  pkgs,
  config,
  lib,
  ...
}:
{
  imports = with self.modules.nixos; [
    basics
    luks-encrypt
    boot_limine
    boot_plymouth
  ];

  boot.loader.timeout = 1;
  boot.plymouth.theme = lib.mkForce "breeze";

  swapDevices = [
    {
      device = "/var/lib/swapfile";
      size = 16 * 1024; # MiB
    }
  ];

  hardware.enableAllFirmware = true;

  hardware.graphics.enable = true;

  services = {
    desktopManager.plasma6.enable = true;

    displayManager = {
      plasma-login-manager.enable = false;
      sddm.enable = true;
      sddm.wayland.enable = false;
      defaultSession = "plasmax11";
    };

    xserver.enable = true;
  };

  services.xserver.videoDrivers = [ "nvidia" ];
  hardware.nvidia = {
    modesetting.enable = true;
    open = false;
    package = config.boot.kernelPackages.nvidiaPackages.legacy_470;
  };

  nixpkgs.config.allowUnfree = true;
  nixpkgs.config.nvidia.acceptLicense = true;

  programs.firefox.enable = true;
  environment.systemPackages = [ pkgs.remmina ];

  # Work around a nixpkgs/systemd-initrd mismatch: config/terminfo.nix
  # adds /etc/terminfo/l/linux from pkgs.ncurses, but this ncurses build
  # does not ship share/terminfo/l/linux, causing initrd assembly to fail.
  boot.initrd.systemd.contents."/etc/terminfo/l/linux".enable = false;
}
