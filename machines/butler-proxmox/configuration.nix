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

    dms-shell
    qmk-full

    "${modulesPath}/profiles/qemu-guest.nix"
    "${modulesPath}/virtualisation/qemu-guest-agent.nix"
  ];

  services.qemuGuest.enable = true;

  # automatically grow root partition to match disk
  boot.growPartition = lib.mkDefault true;

  hardware.graphics.enable = true;
  services.xserver.videoDrivers = [ "nvidia" ];
  hardware.nvidia.open = true;

  hjem.users.ben.imports = with self.modules.hjem; [
    profiles_full
    vesktop
  ];

  users.users.ben.shell = pkgs.zsh;

  programs.zsh.enable = true;
}
