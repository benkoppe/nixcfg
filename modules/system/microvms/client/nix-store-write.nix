{ lib, ... }:
{
  # implements https://microvm-nix.github.io/microvm.nix/shares.html#writable-nixstore-overlay
  flake.modules.nixos."microvms_client_nix-store-write" =
    { config, ... }:
    {
      nix.optimise.automatic = lib.mkForce false;

      microvm.writableStoreOverlay = "/nix/.rw-store";
      microvm.volumes = [
        {
          image = "nix-store-overlay.img";
          mountPoint = config.microvm.writableStoreOverlay;
          size = 4096;
          fsType = "ext4";
        }
      ];
    };
}
