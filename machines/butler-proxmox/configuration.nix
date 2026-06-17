{
  self,
  lib,
  modulesPath,
  pkgs,
  ...
}:
{
  imports = with self.modules.nixos; [
    profiles_butler
    boot_limine

    dms-shell
    qmk-full

    "${modulesPath}/profiles/qemu-guest.nix"
    "${modulesPath}/virtualisation/qemu-guest-agent.nix"
  ];

  services.qemuGuest.enable = true;

  # automatically grow root partition to match disk
  boot.growPartition = lib.mkDefault true;

  fileSystems."/".autoResize = true;

  hardware.graphics.enable = true;
  services.xserver.videoDrivers = [ "nvidia" ];
  hardware.nvidia.open = true;

  environment.systemPackages = with pkgs; [
    kdePackages.qtwayland
    qt5.qtwayland
  ];

  hjem.users.ben.imports = with self.modules.hjem; [
    profiles_full
    vesktop
  ];

  users.users.ben.shell = pkgs.zsh;

  programs.zsh.enable = true;

  networking.interfaces.ens18.ipv4.routes = [
    {
      address = "10.1.0.0";
      prefixLength = 24;
      via = "10.0.1.1";
    }
    {
      address = "10.1.1.0";
      prefixLength = 24;
      via = "10.0.1.1";
    }
    {
      address = "10.2.0.0";
      prefixLength = 24;
      via = "10.0.1.1";
    }
  ];

  swapDevices = [
    {
      device = "/var/lib/swapfile";
      size = 16 * 1024; # MiB
    }
  ];
}
