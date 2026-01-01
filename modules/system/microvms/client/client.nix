{ self, ... }:
{
  flake.modules.nixos."microvms_client" = {
    imports = with self.modules.nixos; [
      microvms_client_network
    ];

    system.stateVersion = "26.05";
  };
}
