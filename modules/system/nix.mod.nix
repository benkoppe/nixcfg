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

      nix = {
        package = pkgs.nixVersions.latest;
        settings.experimental-features = [
          "nix-command"
          "flakes"
        ];
        channel.enable = false;
        inherit registry;
        nixPath = lib.mapAttrsToList (name: flake: "${name}=${flake.outPath}") registryMap;
      };
    };

  flake.modules.nixos.nix = {
    imports = [ self.modules.generic.nix ];

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
    };
  };

  flake.modules.darwin.nix = {
    imports = [ self.modules.generic.nix ];

    nixpkgs.config.allowUnfree = true;

    nix = {
      enable = true;

      settings.trusted-users = [
        "root"
        "@admin"
      ];

      gc = {
        automatic = true;
        options = "--delete-older-than 3d";
        interval = [
          {
            Weekday = 7;
            Hour = 3;
            Minute = 15;
          }
        ];
      };
    };
  };
}
