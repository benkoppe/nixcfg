{ self, lib, ... }:
{
  flake.modules.nixos."microvms_client" = {
    imports = with self.modules.nixos; [
      basics

      microvms_client_network
      microvms_client_nix-store-share
      microvms_client_vsock-ssh
    ];

    options.my.microvm = {
      index = lib.mkOption {
        type = lib.types.int;
        description = "VM's unique identifier, used for networking";
      };
    };

    config = {
      system.stateVersion = "26.05";
    };
  };
}
