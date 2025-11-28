{
  config,
  lib,
  ...
}:
let
  inherit (config.mySnippets) hostName;
  inherit (config.mySnippets.hosts.${hostName}) ipv4;
  isBuildMachine =
    let
      buildHosts = lib.map (m: m.hostName) config.mySnippets.nix.buildMachines;
    in
    lib.elem ipv4 buildHosts;
in
{
  options.myNixOS.programs.nix.enable = lib.mkEnableOption "sane nix configuration";

  config = lib.mkIf config.myNixOS.programs.nix.enable {
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
  };
}
