{ lib, ... }:
{
  options = {
    mySnippets.nix.buildMachines = lib.mkOption {
      type = lib.types.listOf lib.types.attrs;
      description = "List of default nix build machines.";

      default = [
        {
          hostName = "builder-1";
          maxJobs = 6;
          protocol = "ssh-ng";
          speedFactor = 1;
          # sshKey = "";
          sshUser = "builder";
          supportedFeatures = [
            "nixos-test"
            "big-parallel"
            "benchmark"
          ];
          systems = [ "x86_64-linux" ];
          publicHostKey = "c3NoLWVkMjU1MTkgQUFBQUMzTnphQzFsWkRJMU5URTVBQUFBSUJ5aEZuSDFpWHVRaXNhcFpVTXRoSktBTW9jZ2w4dHM3OVBSd2hoTUFwUDIK";
        }
      ];
    };
  };
}
