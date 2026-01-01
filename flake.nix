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
      url = "github:microvm-nix/microvm.nix/pull/453/head";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixos-vfio = {
      url = "github:j-brn/nixos-vfio";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    proxmox-nixos.url = "github:SaumonNet/proxmox-nixos";

    import-tree.url = "github:vic/import-tree";

    treefmt-nix = {
      url = "github:numtide/treefmt-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    systems.url = "github:nix-systems/default";
  };

  nixConfig = {
    extra-substituters = [
      # "https://cache.thekoppe.com?optional=1"
      "https://nix-community.cachix.org"
      "https://cache.nixos.org"
      "https://install.determinate.systems"
      "https://cache.saumon.network/proxmox-nixos"
    ];
    extra-trusted-public-keys = [
      # "cache.thekoppe.com-1:wlGIiKGgTLSwbGKl/364Xw964bP81gYku7wi/BE2sRM="
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
      "cache.flakehub.com-3:hJuILl5sVK4iKm86JzgdXW12Y2Hwd5G07qKtHTOcDCM="
      "proxmox-nixos:D9RYSWpQQC/msZUWphOY2I5RLH5Dd6yQcaHIuug7dWM="
    ];
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
