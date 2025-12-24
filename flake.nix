{
  description = "Infrastructure dendritic clan configuration with flake-parts";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    flake-parts = {
      url = "github:hercules-ci/flake-parts";
      inputs.nixpkgs-lib.follows = "nixpkgs";
    };

    clan-core = {
      url = "git+https://git.clan.lol/clan/clan-core";
      inputs.nixpkgs.follows = "nixpkgs"; # Avoid this if using nixpkgs stable.
      inputs.flake-parts.follows = "flake-parts";
    };

    treefmt-nix = {
      url = "github:numtide/treefmt-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    systems.url = "github:nix-systems/default";
  };

  outputs =
    inputs@{ flake-parts, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } (
      {
        config,
        ...
      }:
      {
        imports = [
          inputs.clan-core.flakeModules.default
          inputs.treefmt-nix.flakeModule
        ];

        systems = import inputs.systems;

        flake.clan = {
          meta = {
            name = "infra";
            domain = "thekoppe";
            description = "Homelab";
          };

          specialArgs = {
            modules = config.flake;
          };

          inventory = {
            machines = { }; # TODO:

            instances = { }; # TODO:
          };
        };

        perSystem =
          {
            config,
            system,
            pkgs,
            ...
          }:
          {
            treefmt = {
              projectRootFile = "flake.nix";
              programs = {
                nixfmt.enable = true;
                statix.enable = true;
                deadnix.enable = true;
              };
            };

            formatter = config.treefmt.build.wrapper;

            devShells.default = pkgs.mkShell {
              packages = [
                inputs.clan-core.packages.${system}.clan-cli
                config.treefmt.build.wrapper
              ];
            };
          };
      }
    );
}
