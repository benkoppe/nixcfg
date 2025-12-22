{
  pkgs,
  config,
  inputs,
  ...
}:
{
  myNixOS.profiles = {
    base.enable = true;
    server.enable = true;
  };

  imports = [
    ./hardware-configuration.nix
    ./display-config.nix
  ];

  boot.loader = {
    systemd-boot.enable = true;
    efi.canTouchEfiVariables = true;
  };

  boot.kernelPackages = pkgs.linuxPackages_latest; # use latest kernel

  boot.initrd =
    let
      secretPath = "/etc/initrd-hostkey";
    in
    {
      clevis = {
        enable = true;
        useTang = true;
        devices."luks-89290a7f-57e5-4f09-9011-11207eb27344".secretFile = secretPath;
        devices."luks-371db3fb-967f-48b7-ad71-c33836031fe4".secretFile = secretPath;
      };
      secrets = {
        "${secretPath}" = config.age.secrets.clevis-luka-boot.path;
      };

      availableKernelModules = [ "r8169" ]; # add ethernet driver module for tang

      systemd = {
        enable = true;
        network.enable = true;
      };
    };

  boot.kernelParams = [ "ip=dhcp" ];

  age.secrets.clevis-luka-boot = {
    file = "${inputs.secrets}/programs/clevis/luka-boot.age";
    path = "/etc/initrd-hostkey";
    symlink = false;
  };

  networking.hostName = config.mySnippets.hostName;

  # Enable networking
  networking.networkmanager.enable = true;
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  # programs.gnupg.agent = {
  #   enable = true;
  #   enableSSHSupport = true;
  # };

  programs.steam = {
    enable = true;
  };
}
