{ self, lib, ... }:
let
  inherit (lib) mkOption types;
in
{
  flake.modules.nixos."microvms_host_service-vms" =
    { config, ... }:
    {
      options.my.service-vms = mkOption {
        type = types.attrsOf (
          types.submodule (
            { name, ... }:
            {
              options = {
                id = mkOption {
                  type = types.int;
                  description = "Unique VM identifier";
                };
                modules = mkOption {
                  type = types.listOf types.anything;
                  default = [ ];
                  description = "List of nixos modules to include in the vm.";
                };
                name = mkOption {
                  type = types.str;
                  description = "Name for the VM";
                  default = name;
                };
              };
            }
          )
        );
      };

      config =
        let
          vms = config.my.service-vms;
        in
        {
          sops.secrets = lib.mapAttrs' (name: _: {
            name = "age-keys/${name}/key.txt";
            value = {
              owner = "microvm";
              sopsFile = config.clan.core.settings.directory + "/sops/secrets/vm-${name}-age.key/secret";
              format = "binary";
            };
          }) vms;

          microvm.vms = lib.mapAttrs' (name: cfg: {
            inherit (cfg) name;
            value = {
              pkgs = null;
              specialArgs = {
                hostConfig = config;
              };

              config = {
                imports = [ self.outputs.clan.outputs.moduleForMachine."vm-${name}" ] ++ cfg.modules;

                my.microvm.id = cfg.id;

                networking.hostName = lib.mkForce cfg.name;

                sops.age.keyFile = "/var/lib/sops-nix-mnt/key.txt";

                microvm.shares = [
                  {
                    source = "/run/secrets/age-keys/${name}";
                    mountPoint = "/var/lib/sops-nix-mnt";
                    tag = "age-mnt-${name}";
                    proto = "virtiofs";
                    readOnly = true;
                  }
                ];
                fileSystems."/var/lib/sops-nix-mnt".neededForBoot = true;
              };
            };
          }) vms;
        };
    };
}
