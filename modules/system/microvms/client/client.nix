{ self, ... }:
{
  flake.modules.nixos."microvms_client" = {
    imports = with self.modules.nixos; [
      basics

      microvms_client_network
      microvms_client_nix_store_share
    ];

    system.stateVersion = "26.05";
  };
}
