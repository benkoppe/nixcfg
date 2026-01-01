{ lib, ... }:
{
  flake.modules.nixos."microvms_client_nix-store-write" = {
    nix.optimise.automatic = lib.mkForce false;

    microvm.writableStoreOverlay = "/nix/.rw-store";
    fileSystems."/nix/.rw-store" = {
      fsType = "tmpfs";
      options = [
        "mode=0755"
        "size=4G"
      ];
    };

  };
}
