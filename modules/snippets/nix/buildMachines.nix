{ lib, config, ... }:
{
  options = {
    mySnippets.nix.buildMachines = lib.mkOption {
      type = lib.types.listOf lib.types.attrs;
      description = "List of default nix build machines.";

      default = [
        (
          let
            inherit (config.mySnippets.hosts) builder-1;
          in
          {
            hostName = builder-1.ipv4;
            maxJobs = 10;
            protocol = "ssh-ng";
            speedFactor = 2;
            sshKey = "${config.mySnippets.primaryHome}/.ssh/pve/builder-1";
            sshUser = "builder";
            supportedFeatures = [
              "nixos-test"
              "big-parallel"
              "benchmark"
            ];
            systems = [ "x86_64-linux" ];
            publicHostKey = "c3NoLWVkMjU1MTkgQUFBQUMzTnphQzFsWkRJMU5URTVBQUFBSUJ5aEZuSDFpWHVRaXNhcFpVTXRoSktBTW9jZ2w4dHM3OVBSd2hoTUFwUDIK";
          }
        )
      ];
    };
  };
}
