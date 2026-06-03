{
  self,
  lib,
  modulesPath,
  ...
}:
{
  imports = with self.modules.nixos; [
    basics
    development

    hjem
    niri

    "${modulesPath}/virtualisation/vmware-guest.nix"
  ];

  virtualisation.vmware.guest.enable = true;

  # automatically grow root partition to match disk
  boot.growPartition = lib.mkDefault true;

  # fixes booting on fusion
  # without this, it would get stuck on "nixos-activation.service" until I spammed enter
  boot.loader.grub.enable = false;
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.systemd-boot.consoleMode = "0";

  # Setup qemu so we can run x86_64 binaries
  boot.binfmt.emulatedSystems = [ "x86_64-linux" ];

  # Lots of stuff that uses aarch64 that claims doesn't work, but actually works.
  nixpkgs.config.allowUnfree = true;
  nixpkgs.config.allowUnsupportedSystem = true;

  hardware.graphics.enable = true;

  hjem.users.ben = {
    user = "ben";
    directory = "/home/ben";

    imports = with self.modules.hjem; [
      niri
      browsers
    ];
  };
}
