{
  self,
  lib,
  modulesPath,
  ...
}:
{
  imports = with self.modules.nixos; [
    profiles_butler

    "${modulesPath}/virtualisation/vmware-guest.nix"
  ];

  virtualisation.vmware.guest = {
    enable = true;
    headless = false;
  };

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
    rum.desktops.niri.config =
      lib.mkAfter
        # kdl
        ''
          output "Virtual-1" {
            scale 1.8
          }
        '';
  };
}
