{
  description = "Ben's Nix System Flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixpkgs-stable.url = "github:NixOS/nixpkgs/nixos-25.05";

    agenix = {
      url = "github:ryantm/agenix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    colmena.url = "github:zhaofengli/colmena";

    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    determinate.url = "https://flakehub.com/f/DeterminateSystems/determinate/*";

    flake-parts.url = "github:hercules-ci/flake-parts";

    home-manager = {
      url = "github:nix-community/home-manager/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    mnw.url = "github:Gerg-L/mnw";

    nix-darwin = {
      url = "github:nix-darwin/nix-darwin/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-homebrew.url = "github:zhaofengli/nix-homebrew";

    nixos-generators = {
      url = "github:nix-community/nixos-generators";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Non-flake inputs
    homebrew-bundle = {
      url = "github:homebrew/homebrew-bundle";
      flake = false;
    };
    homebrew-core = {
      url = "github:homebrew/homebrew-core";
      flake = false;
    };
    homebrew-cask = {
      url = "github:homebrew/homebrew-cask";
      flake = false;
    };
    homebrew-sst-tap = {
      url = "github:sst/homebrew-tap";
      flake = false;
    };

    secrets = {
      url = "git+ssh://git@github.com/benkoppe/nix-secrets.git";
      flake = false;
    };
  };

  nixConfig = {
    accept-flake-config = true;

    extra-substituters = [
      "https://nix-community.cachix.org"
      "https://cache.nixos.org"
      "https://install.determinate.systems"
      "https://colmena.cachix.org"
    ];
    extra-trusted-public-keys = [
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
      "cache.flakehub.com-3:hJuILl5sVK4iKm86JzgdXW12Y2Hwd5G07qKtHTOcDCM="
      "colmena.cachix.org-1:7BzpDnjjH8ki2CT3f6GdOk7QAzPOl+1t3LvTLXqYcSg="
    ];

    experimental-features = [
      "cgroups"
      "flakes"
      "nix-command"
      "parallel-eval"
    ];

    builders-use-substitutes = true;
    # flake-registry = "";
    http-connections = 50;
    lazy-trees = true;
    show-trace = true;
    trusted-users = [
      "root"
      "builder"
      "@build"
      "@wheel"
      "@admin"
    ];
    use-cgroups = true;
    warn-dirty = false;
  };

  outputs =
    inputs@{ flake-parts, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [
        "aarch64-darwin"
        "x86_64-linux"
      ];

      imports = [
        ./modules/flake
        inputs.home-manager.flakeModules.home-manager
      ];
    };
}
