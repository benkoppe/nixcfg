{ self, lib, ... }:
let
  inherit (lib) mkOption types;
in
{
  flake.modules.nixos."microvms_host_service-vms-2" =
    { config, ... }:
    {
      options.my.service-vms-2 = mkOption {
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
          vms = config.my.service-vms-2;
        in
        {
          sops.secrets = lib.mapAttrs' (name: _: {
            name = "vm-${name}-age.key";
            value = {
              owner = "microvm";
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

                microvm.credentialFiles = {
                  SOPS_AGE_KEY = "/var/run/secrets/vm-${name}-age.key";
                };

                services.userborn.enable = true; # <--- trigger sops-nix to use a stage 2 systemd unit, rather than activationscripts in stage1
                systemd.services.bootstrap-secrets = {
                  wantedBy = [ "sysinit.target" ];
                  after = [ "systemd-sysusers.service" ];
                  before = [
                    "sops-install-secrets.service"
                    "sshd.service"
                  ];
                  serviceConfig = {
                    ImportCredential = "SOPS_AGE_KEY";
                    Type = "oneshot";
                  };
                  script = ''
                    mkdir -p /var/lib/sops-nix-mnt
                    cat $CREDENTIALS_DIRECTORY/SOPS_AGE_KEY > /var/lib/sops-nix-mnt/key.txt
                    chmod 0600 /var/lib/sops-nix-mnt/key.txt
                  '';
                };
              };
            };
          }) vms;
        };
    };
}
