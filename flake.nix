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

    determinate = {
      url = "https://flakehub.com/f/DeterminateSystems/determinate/*";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    terranix = {
      url = "github:terranix/terranix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    microvm = {
      url = "github:microvm-nix/microvm.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixos-vfio = {
      url = "github:j-brn/nixos-vfio";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    import-tree.url = "github:vic/import-tree";

    treefmt-nix = {
      url = "github:numtide/treefmt-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    systems.url = "github:nix-systems/default";
  };

  outputs =
    inputs@{ flake-parts, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      imports = [
        inputs.flake-parts.flakeModules.modules
        inputs.clan-core.flakeModules.default
        inputs.terranix.flakeModule
        inputs.treefmt-nix.flakeModule
        (inputs.import-tree ./modules)
      ];

      systems = import inputs.systems;

      flake.clan = {
        meta = {
          name = "infra";
          domain = "thekoppe";
          description = "Homelab";
        };

        inventory = {
          machines = {
            luka = {
              deploy.targetHost = "root@luka";
              tags = [ "development" ];
            };
            bird.deploy.targetHost = "root@165.1.75.12";
          };

          instances = {
            admin = {
              roles.default.tags.all = { };
              roles.default.settings = {
                allowedKeys = {
                  colmena = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJgiH4Iu1GUe9Hd40cSnQH94EHj0VmjXdbsaBED2WMHT colmena";
                };
                certificateSearchDomains = [ "thekoppe.com" ];
              };
            };

            user-ben-dev = {
              module.name = "users";

              roles.default.tags.development = { };
              roles.default.settings = {
                user = "ben";
                share = true;
                groups = [
                  "wheel"
                  "networkmanager"
                  "video"
                  "input"
                ];
              };
            };

            clan-cache = {
              module.name = "trusted-nix-caches";
              roles.default.tags.all = { };
              roles.default.extraModules = [ ];
            };
          };
        };
      };

      perSystem =
        {
          pkgs,
          inputs',
          config,
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
              inputs'.clan-core.packages.clan-cli
              config.treefmt.build.wrapper
            ];
          };

          # Customize nixpkgs
          # _module.args.pkgs = import inputs.nixpkgs {
          #   inherit system;
          #   config.allowUnfree = true;
          #   overlays = [ ];
          # };
          # clan.pkgs = pkgs;
        };
    };
}
