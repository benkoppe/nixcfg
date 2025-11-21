{ lib, config, ... }:
{
  options = {
    mySnippets.nix.buildMachines = lib.mkOption {
      type = lib.types.listOf lib.types.attrs;
      description = "List of default nix build machines.";

      default = [
        (
          let
            inherit (config.mySnippets.hosts) nix-builder;
          in
          {
            hostName = nix-builder.ipv4;
            maxJobs = 10;
            protocol = "ssh-ng";
            speedFactor = 2;
            sshKey = "${config.mySnippets.primaryHome}/.ssh/pve/nix-builder";
            sshUser = "builder";
            supportedFeatures = [
              "nixos-test"
              "big-parallel"
              "benchmark"
            ];
            systems = [ "x86_64-linux" ];
            publicHostKey = "c3NoLWVkMjU1MTkgQUFBQUMzTnphQzFsWkRJMU5URTVBQUFBSUVvTlJteVV2Vm5nVTkzZnJZNWEzUjRXSHFFcllZcktyQUxaS0RiODVtL3ogcm9vdEBuaXgtYnVpbGRlcgo=";
          }
        )
      ];
    };
  };
}
