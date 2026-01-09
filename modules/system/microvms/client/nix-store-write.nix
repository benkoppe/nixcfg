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

      # the nix store will forget everything in the overlay on boot
      # address this by just deleting the image each startup
      # see: https://microvm-nix.github.io/microvm.nix/shares.html#writable-nixstore-overlay:~:text=writableStoreOverlay%3B%0A%20%20%20%20size%20%3D%202048%3B%0A%20%20%7D%20%5D%3B%0A%7D-,The%20Nix%20database,-will%20forget%20all
      microvm.preStart = ''
        rm -f nix-store-overlay.img
      '';
    };
}
