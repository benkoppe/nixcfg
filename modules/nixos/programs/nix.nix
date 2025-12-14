{
  config,
  lib,
  inputs,
  ...
}:
let
  inherit (config.mySnippets) hostName;

  hostCfg =
    if lib.hasAttr hostName config.mySnippets.hosts then config.mySnippets.hosts.${hostName} else null;

  ipv4 = if hostCfg != null then hostCfg.ipv4 else null;

  isBuildMachine =
    let
      buildHosts = lib.map (m: m.hostName) config.mySnippets.nix.buildMachines;
    in
    hostCfg != null && lib.elem ipv4 buildHosts;
in
{
  options.myNixOS.programs.nix = {
    enable = lib.mkEnableOption "sane nix configuration";

    accessTokens.enable = lib.mkEnableOption "use access tokens for github private inputs access";
  };

  config = lib.mkIf config.myNixOS.programs.nix.enable (
    lib.mkMerge [
      {
        nix = {
          buildMachines = lib.mkIf config.services.tailscale.enable (
            lib.filter (m: m.hostName != config.networking.hostName) config.mySnippets.nix.buildMachines
          );

          distributedBuilds = true;

          gc = {
            automatic = true;

            options = if isBuildMachine then "--delete-older-than 20d" else "--delete-older-than 3d";

            persistent = true;
            randomizedDelaySec = "60min";
          };

          extraOptions = ''
            min-free = ${toString (1 * 1024 * 1024 * 1024)}   # 1 GiB
            max-free = ${toString (5 * 1024 * 1024 * 1024)}   # 5 GiB
          '';

          optimise = {
            automatic = true;
            persistent = true;
            randomizedDelaySec = "60min";
          };

          inherit (config.mySnippets.nix) settings;
        };
      }

      (lib.mkIf config.myNixOS.programs.nix.accessTokens.enable {
        nix.extraOptions = lib.mkAfter "!include ${config.age.secrets.nix-access-tokens.path}";

        age.secrets.nix-access-tokens = {
          file = "${inputs.secrets}/programs/nix/access-tokens.age";
          mode = "444";
        };
      })

      {
        nix =
          let
            registryMap = lib.filterAttrs (_: v: lib.isType "flake" v) inputs;
          in
          {
            channel.enable = false;

            registry = lib.mapAttrs (_: flake: { inherit flake; }) registryMap;

            nixPath = lib.mapAttrsToList (name: flake: "${name}=${flake.outPath}") registryMap;
          };
      }
    ]
  );
}
