{ inputs, ... }:
{
  flake.modules.darwin.tmignore =
    { config, ... }:
    let
      inherit (config.system) primaryUser;
      inherit (config.users.users.${primaryUser}) home;
    in
    {
      imports = [
        inputs.tmignore.darwinModules.tmignore
      ];

      services.tmignore = {
        enable = true;

        command = "all";
        mode = "apply"; # defaults to dry-run

        scan.roots = [
          "${home}/Developer"
        ];

        global.extraTargets = {
          lima_disks.path = ".config/lima/_disks";
          colima_vm.path = ".config/lima/colima";
          vmware_fusion_vms.path = "Virtual Machines.localized";
        };

        stdoutPath = "${home}/Library/Logs/tmignore/tmignore.log";
        stderrPath = "${home}/Library/Logs/tmignore/tmignore.error.log";

        runAtLoad = true;
      };
    };
}
