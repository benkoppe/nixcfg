{
  self,
  inputs,
  lib,
  ...
}:
let
  registryInputNames = [
    "nixpkgs"
    "nixpkgs-stable"
  ];

  registryMap = lib.filterAttrs (
    name: value: builtins.elem name registryInputNames && lib.isType "flake" value
  ) inputs;

  registry = lib.mapAttrs (_: flake: { inherit flake; }) registryMap;
in
{
  flake.modules.generic.nix =
    { pkgs, ... }:
    let
      inherit (pkgs.stdenv.hostPlatform) system;
    in
    {
      environment.systemPackages = with pkgs; [
        nix-output-monitor
        nh
        inputs.nix-diff-rs.packages.${system}.default
        inputs.nix-tree-rs.packages.${system}.default
      ];
    };

  flake.modules.nixos.nix = {
    imports = [
      inputs.determinate.nixosModules.default
      self.modules.generic.nix
    ];

    nixpkgs.config.allowUnfree = true;

    nix = {
      gc = {
        automatic = true;
        options = "--delete-older-than 3d";
        persistent = true;
        randomizedDelaySec = "60min";
      };

      # run GC when there is less than min-free space until there is max-free space
      extraOptions = ''
        min-free = ${toString (1 * 1024 * 1024 * 1024)} # 1 GiB
        max-free = ${toString (5 * 1024 * 1024 * 1024)} # 5 GiB
      '';

      optimise = {
        automatic = true;
        persistent = true;
        randomizedDelaySec = "60min";
      };

      settings = {
        trusted-users = [
          "root"
          "@wheel"
        ];
        # https://discourse.nixos.org/t/why-does-nix-direnv-recommend-setting-nix-settings-keep-outputs/31081
        keep-outputs = true;
      };
    }
    // {
      channel.enable = false;
      inherit registry;
      nixPath = lib.mapAttrsToList (name: flake: "${name}=${flake.outPath}") registryMap;
    };
  };

  flake.modules.darwin.nix = {
    imports = [
      inputs.determinate.darwinModules.default
      self.modules.generic.nix
    ];

    nixpkgs.config.allowUnfree = true;

    nix.enable = false;

    determinateNix = {
      enable = true;

      customSettings = {
        trusted-users = [
          "root"
          "@admin"
        ];
      };

      inherit registry;

      # determinateNixd = {
      #   telemetry.sentry.endpoint = null;
      # };
    };
  };
}
