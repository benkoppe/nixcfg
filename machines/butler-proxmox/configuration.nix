{
  self,
  lib,
  modulesPath,
  ...
}:
{
  imports = with self.modules.nixos; [
    basics

    hjem
    niri

    "${modulesPath}/profiles/qemu-guest.nix"
    "${modulesPath}/virtualisation/qemu-guest-agent.nix"
  ];

  services.qemuGuest.enable = true;

  # automatically grow root partition to match disk
  boot.growPartition = lib.mkDefault true;

  hardware.graphics.enable = true;
  services.xserver.videoDrivers = [ "nvidia" ];
  hardware.nvidia.open = true;
}
