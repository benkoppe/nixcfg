{
  self,
  inputs,
  ...
}:
{
  flake = {
    diskoConfigurations = {
      simple-ext4 = ../disko/simple-ext4.nix;
    };

    nixosConfigurations = inputs.nixpkgs.lib.genAttrs [ "russ" ] (
      host:
      inputs.nixpkgs.lib.nixosSystem {
        modules = [
          ../../hosts/${host}
          ../nixos
        ];

        specialArgs = { inherit self; };
      }
    );
  };
}
