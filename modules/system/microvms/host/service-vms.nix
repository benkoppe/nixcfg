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
          types.submodule {
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
            };
          }
        );
      };

      config = {
        microvm.vms = lib.mapAttrs (_name: cfg: {
          pkgs = null;
          specialArgs = {
            hostConfig = config;
          };

          config = {
            imports =
              with self.modules.nixos;
              [
                microvms_client
              ]
              ++ cfg.modules;

            my.microvm.id = cfg.id;
          };
        }) config.my.service-vms;
      };
    };
}
