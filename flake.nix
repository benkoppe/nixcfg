{
  description = "Infrastructure dendritic clan configuration with flake-parts";

  inputs = {
    nixpkgs.url = "https://flakehub.com/f/DeterminateSystems/nixpkgs-weekly/0.1";

    nixpkgs-vaultwarden.url = "github:NixOS/nixpkgs/701b3fd657f582f3464354b24baf93e1ee579b03";

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
      inputs.systems.follows = "systems";
    };

    determinate = {
      url = "https://flakehub.com/f/DeterminateSystems/determinate/*";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    hjem = {
      url = "github:feel-co/hjem";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    hjem-rum = {
      url = "github:snugnug/hjem-rum";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.hjem.follows = "hjem";
    };

    llm-agents = {
      url = "github:numtide/llm-agents.nix";
      inputs.treefmt-nix.follows = "treefmt-nix";
      inputs.flake-parts.follows = "flake-parts";
      inputs.systems.follows = "systems";
    };

    direnv-instant = {
      url = "github:Mic92/direnv-instant";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.treefmt-nix.follows = "treefmt-nix";
      inputs.flake-parts.follows = "flake-parts";
    };

    niks3 = {
      url = "github:Mic92/niks3";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.treefmt-nix.follows = "treefmt-nix";
    };

    nix-diff-rs = {
      url = "github:Mic92/nix-diff-rs";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.treefmt-nix.follows = "treefmt-nix";
      inputs.flake-parts.follows = "flake-parts";
    };

    nix-tree-rs = {
      url = "github:Mic92/nix-tree-rs";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.treefmt-nix.follows = "treefmt-nix";
      inputs.flake-parts.follows = "flake-parts";
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

    vgpu4nixos.url = "github:benkoppe/vgpu4nixos";

    fastapi-dls-nixos = {
      url = "github:mrzenc/fastapi-dls-nixos";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    proxmox-nixos.url = "github:SaumonNet/proxmox-nixos";

    helium = {
      url = "github:amaanq/helium-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    copyparty.url = "github:9001/copyparty";

    github2forgejo = {
      url = "github:RGBCube/GitHub2Forgejo";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    lancache-nix.url = "github:menixator/lancache.nix";

    nix-topology = {
      url = "github:oddlama/nix-topology";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.flake-parts.follows = "flake-parts";
    };
    selfhst-icons = {
      url = "github:selfhst/icons";
      flake = false;
    };

    import-tree.url = "github:vic/import-tree";

    treefmt-nix = {
      url = "github:numtide/treefmt-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nvim-flake = {
      url = "github:benkoppe/nvim-flake";
    };

    tmignore = {
      url = "github:benkoppe/tmignore";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.nix-darwin.follows = "nix-darwin";
      inputs.flake-parts.follows = "flake-parts";
    };

    systems.url = "github:nix-systems/default";

    # non-flake inputs
    tmux-sessionizer = {
      url = "github:theprimeagen/tmux-sessionizer";
      flake = false;
    };

    dmmulroy-dotfiles = {
      url = "github:dmmulroy/.dotfiles";
      flake = false;
    };
    pi-agent-extensions = {
      url = "github:rytswd/pi-agent-extensions";
      flake = false;
    };

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
      "https://cache.thekoppe.com?priority=10&optional=1"
      "https://nix-community.cachix.org"
      "https://cache.nixos.org"
      "https://install.determinate.systems"
      "https://cache.clan.lol"
      "https://cache.numtide.com"
      "https://cache.thalheim.io"
      "https://cache.saumon.network/proxmox-nixos"
      "https://niri-flake-benkoppe.cachix.org"
      "https://niri.cachix.org"
    ];
    extra-trusted-public-keys = [
      "cache.thekoppe.com-1:k6bpXbbySclfYx+w7EoTxq/R/mveWHpOe7daqtNsLA0="
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
      "cache.flakehub.com-3:hJuILl5sVK4iKm86JzgdXW12Y2Hwd5G07qKtHTOcDCM="
      "cache.clan.lol-1:3KztgSAB5R1M+Dz7vzkBGzXdodizbgLXGXKXlcQLA28="
      "niks3.numtide.com-1:DTx8wZduET09hRmMtKdQDxNNthLQETkc/yaX7M4qK0g="
      "cache.thalheim.io-1:R7msbosLEZKrxk/lKxf9BTjOOH7Ax3H0Qj0/6wiHOgc="
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
        inputs.nix-topology.flakeModule
        inputs.treefmt-nix.flakeModule
        (inputs.import-tree ./modules)
        ./pkgs/flake-module.nix
        ./clan.nix
      ];

      systems = import inputs.systems;

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
