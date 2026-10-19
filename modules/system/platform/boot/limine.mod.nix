{ lib, ... }:
{
  flake.modules.nixos.boot_limine = {
    boot.loader = {
      limine = {
        enable = lib.mkDefault true;
        efiSupport = lib.mkDefault true;
        efiInstallAsRemovable = lib.mkDefault true;
        maxGenerations = lib.mkDefault 10;
      };

      efi.canTouchEfiVariables = lib.mkDefault true;
    };
  };
}
