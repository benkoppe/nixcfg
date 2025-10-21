{
  self,
  inputs,
  ...
}:
{
  flake = {
    colmenaHive = inputs.colmena.lib.makeHive {
      meta = {
        nixpkgs = import inputs.nixpkgs {
          system = "x86_64-linux";
          overlays = [ ];
        };
        specialArgs = { inherit self; };
      };

      russ = {
        deployment = {
          targetHost = "russ";
          targetUser = "root";
        };
        imports = [
          ../../hosts/russ
          ../nixos
        ];
      };

      builder-1 = {
        deployment = {
          targetHost = "builder-1-root";
          targetUser = "root";
        };
        imports = [
          ../../hosts/microhosts/builder-1.nix
          ../nixos
        ];
      };
    };
  };
}
