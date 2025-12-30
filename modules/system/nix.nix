{ inputs, lib, ... }:
{
  flake.modules.nixos.nix = {
    imports = [ inputs.determinate.nixosModules.default ];

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

    }
    // (
      let
        registryMap = lib.filterAttrs (_: v: lib.isType "flake" v) inputs;
      in
      {
        channel.enable = false;
        registry = lib.mapAttrs (_: flake: { inherit flake; }) registryMap;
        nixPath = lib.mapAttrsToList (name: flake: "${name}=${flake.outPath}") registryMap;
      }
    );
  };
}
