{ lib, config, ... }:
{
  options.flake.machines = lib.mkOption {
    description = "Machine metadata shared by deployment and inter-machine configuration";
    default = { };
    type = lib.types.lazyAttrsOf (
      lib.types.submodule (
        { name, ... }:
        {
          options = {
            ip.addresses4 = lib.mkOption {
              type = lib.types.listOf lib.types.str;
              default = [ ];
              description = "IPv4 addresses exported for inter-machine configuration";
            };

            ssh = lib.mkOption {
              default = { };
              description = "SSH connection metadata, or null to leave deployment configuration unchanged";
              type = lib.types.nullOr (
                lib.types.submodule {
                  options = {
                    hostName = lib.mkOption {
                      type = lib.types.str;
                      default = name;
                      description = "Hostname or IP used to reach the machine over SSH";
                    };

                    user = lib.mkOption {
                      type = lib.types.str;
                      default = "root";
                      description = "Interactive SSH login user";
                    };

                    deployUser = lib.mkOption {
                      type = lib.types.str;
                      default = "root";
                      description = "SSH login user for Clan deployments";
                    };

                    port = lib.mkOption {
                      type = lib.types.port;
                      default = 22;
                      description = "SSH port";
                    };
                  };
                }
              );
            };
          };
        }
      )
    );
  };

  config.flake.clan.inventory.machines = lib.mapAttrs (
    _: machine:
    let
      inherit (machine) ssh;
    in
    {
      deploy.targetHost = lib.mkDefault (
        "${ssh.deployUser}@${ssh.hostName}" + lib.optionalString (ssh.port != 22) ":${toString ssh.port}"
      );
    }
  ) (lib.filterAttrs (_: machine: machine.ssh != null) config.flake.machines);
}
