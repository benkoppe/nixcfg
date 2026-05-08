{
  description = "Infrastructure dendritic clan configuration with flake-parts";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    flake-parts = {
      url = "github:hercules-ci/flake-parts";
      inputs.nixpkgs-lib.follows = "nixpkgs";
    };

    nix-darwin = {
      url = "github:nix-darwin/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    clan-core = {
      url = "git+https://git.clan.lol/clan/clan-core";
      inputs.nixpkgs.follows = "nixpkgs"; # Avoid this if using nixpkgs stable.
      inputs.nix-darwin.follows = "nix-darwin";
      inputs.flake-parts.follows = "flake-parts";
    };

    determinate = {
      url = "https://flakehub.com/f/DeterminateSystems/determinate/*";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    hjem = {
      url = "github:feel-co/hjem";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.nix-darwin.follows = "nix-darwin";
    };
    hjem-rum = {
      url = "github:snugnug/hjem-rum";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.hjem.follows = "hjem";
      inputs.ndg.follows = "";
      inputs.treefmt-nix.follows = "";
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

    vgpu4nixos.url = "github:mrzenc/vgpu4nixos";

    fastapi-dls-nixos = {
      url = "github:mrzenc/fastapi-dls-nixos";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    proxmox-nixos.url = "github:SaumonNet/proxmox-nixos";

    copyparty.url = "github:9001/copyparty";

    github2forgejo = {
      url = "github:RGBCube/GitHub2Forgejo";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    lancache-nix.url = "github:menixator/lancache.nix";

    niri-flake.url = "github:sodiboo/niri-flake";

    import-tree.url = "github:vic/import-tree";

    treefmt-nix = {
      url = "github:numtide/treefmt-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nvim-flake = {
      url = "github:benkoppe/nvim-flake";
    };

    systems.url = "github:nix-systems/default";

    # darwin inputs
    nix-homebrew.url = "github:zhaofengli/nix-homebrew";

    # non-flake darwin inputs
    homebrew-core = {
      url = "github:homebrew/homebrew-core";
      flake = false;
    };
    homebrew-cask = {
      url = "github:homebrew/homebrew-cask";
      flake = false;
    };
  };

  nixConfig = {
    extra-substituters = [
      # "https://cache.thekoppe.com?optional=1"
      "https://nix-community.cachix.org"
      "https://cache.nixos.org"
      "https://install.determinate.systems"
      "https://cache.saumon.network/proxmox-nixos"
      "https://niri-flake-benkoppe.cachix.org"
      "https://niri.cachix.org"
    ];
    extra-trusted-public-keys = [
      # "cache.thekoppe.com-1:wlGIiKGgTLSwbGKl/364Xw964bP81gYku7wi/BE2sRM="
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
      "cache.flakehub.com-3:hJuILl5sVK4iKm86JzgdXW12Y2Hwd5G07qKtHTOcDCM="
      "proxmox-nixos:D9RYSWpQQC/msZUWphOY2I5RLH5Dd6yQcaHIuug7dWM="
      "niri-flake-benkoppe.cachix.org-1:wMG1r1sgn0hQN1esSnSRTnLUB0fQegCEUhA2TDlRwzI="
      "niri.cachix.org-1:Wv0OmO7PsuocRKzfDoJ3mulSl7Z6oezYhGhR+3W2964="
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

      flake.clan =
        { self, ... }:
        {
          meta = {
            name = "infra";
            domain = "thekoppe.com";
            description = "Homelab";
          };

          inventory = {
            machines = {
              butler = {
                tags = [ "development" ];
              };
              luka = {
                deploy.targetHost = "root@luka";
                tags = [ "development" ];
              };
              bird.deploy.targetHost = "root@165.1.75.12";
              dray = {
                deploy.targetHost = "root@dray";
                tags = [ "development" ];
              };
              shai = {
                deploy.targetHost = "root@shai";
                tags = [ "development" ];
              };

              jordan = {
                machineClass = "darwin";
              };
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
                roles.default.extraModules = with self.modules.nixos; [ development ];
              };

              clan-cache = {
                module.name = "trusted-nix-caches";
                roles.default.tags.all = { };
                roles.default.extraModules = [ ];
              };

              # use dray as cache proxy
              ncps = {
                roles.server.machines."dray".settings = {
                  dataPath = "/var/lib/ncps";
                  caches = [
                    "https://cache.nixos.org"
                    "https://nix-community.cachix.org"
                    "https://install.determinate.systems"
                    "https://cache.saumon.network/proxmox-nixos"
                    "https://nixpkgs-unfree.cachix.org"
                    "https://nix-gaming.cachix.org"
                    "https://cuda-maintainers.cachix.org"
                  ];
                  publicKeys = [
                    "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
                    "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
                    "cache.flakehub.com-3:hJuILl5sVK4iKm86JzgdXW12Y2Hwd5G07qKtHTOcDCM="
                    "proxmox-nixos:D9RYSWpQQC/msZUWphOY2I5RLH5Dd6yQcaHIuug7dWM="
                    "nixpkgs-unfree.cachix.org-1:hqvoInulhbV4nJ9yJOEr+4wxhDV4xq2d1DK7S6Nj6rs="
                    "nix-gaming.cachix.org-1:nbjlureqMbRAxR1gJ/f3hxemL9svXaZF/Ees8vCUUs4="
                    "cuda-maintainers.cachix.org-1:0dq3bujKpuEPMCX6U4WylrUDZ9JyUG0VpVZa7CNfq5E="
                  ];
                };

                roles.client.machines."luka".settings = { };
                roles.client.machines."shai".settings = { };
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
              pkgs.nh
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
