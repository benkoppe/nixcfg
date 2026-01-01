{ self, ... }:
{
  flake.modules.nixos."microvms_client" = {
    imports = with self.modules.nixos; [ microvms_network-client ];

    system.stateVersion = "26.05";
  };
}
