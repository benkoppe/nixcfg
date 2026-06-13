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

  hjem.users.ben.imports = with self.modules.hjem; [
    profiles_full
    vesktop
  ];

  users.users.ben.shell = pkgs.zsh;

  programs.zsh.enable = true;

  services.tailscale = {
    enable = true;
    useRoutingFeatures = "client";
    extraSetFlags = [ "--accept-routes" ];
  };

  swapDevices = [
    {
      device = "/var/lib/swapfile";
      size = 16 * 1024; # MiB
    }
  ];
}
