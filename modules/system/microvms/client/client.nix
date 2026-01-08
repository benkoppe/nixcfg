{ self, lib, ... }:
{
  flake.modules.nixos."microvms_client" = {
    imports = with self.modules.nixos; [
      basics

      microvms_client_network
      microvms_client_vsock-ssh

      microvms_client_nix-store-read
      microvms_client_nix-store-write

      self.inputs.microvm.nixosModules.microvm
    ];

    options.my.microvm = {
      id = lib.mkOption {
        type = lib.types.int;
        description = "VM's unique identifier, used for networking";
      };
    };

    config = {
      system.stateVersion = "26.05";

      nixpkgs.hostPlatform = "x86_64-linux";

      clan.core.deployment.requireExplicitUpdate = true;
    };
  };
}
