{ self, inputs, ... }:
{
  flake.modules.nixos."microvms_host" = {
    imports = with self.modules.nixos; [
      inputs.microvm.nixosModules.host

      microvms_host_network
    ];
  };
}
