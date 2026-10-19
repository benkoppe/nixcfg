{ lib, ... }:
let
  inherit (lib)
    flip
    mapAttrsToList
    mkIf
    mkMerge
    mkVMOverride
    mod
    optional
    optionalAttrs
    optionals
    ;
in
{
  flake.modules.nixos."microvms_host_topology" =
    { config, ... }:
    let
      vms = config.my.service-vms;
      microvmNetwork = "${config.networking.hostName}-microvms";

      mapVms =
        f:
        flip mapAttrsToList config.microvm.vms (
          vmName: vm:
          f (if vm.flake != null then vm.flake.nixosConfigurations.${vmName}.config else vm.config.config)
        );

      vmInfo =
        vmCfg:
        let
          ramGB10 = builtins.floor (10 * vmCfg.microvm.mem / 1024);
          ramGB = if mod ramGB10 10 == 0 then ramGB10 / 10 else ramGB10 / 10.0;
        in
        mkVMOverride "microvm, ${toString ramGB}GB RAM";

      vmAddresses =
        vmCfg: optional (vmCfg ? my && vmCfg.my ? microvm && vmCfg.my.microvm ? ipv4) vmCfg.my.microvm.ipv4;
    in
    {
      config = mkIf (vms != { }) {
        topology.extractors.microvm.enable = false;
        topology.extractors.systemd-network.enable = false;

        topology.networks.${microvmNetwork} = {
          name = "${config.networking.hostName} MicroVMs";
          cidrv4 = "${config.my.microvms.network.subnet}.0/24";
        };

        topology.self.interfaces.microvms = {
          virtual = true;
          type = "bridge";
          addresses = [ config.my.microvms.network.gateway ];
          network = microvmNetwork;
        };

        topology.dependentConfigurations = mapVms (
          vmCfg: optionals (vmCfg ? topology) vmCfg.topology.definitions
        );

        topology.nodes = mkMerge (
          mapVms (
            vmCfg:
            optionalAttrs (vmCfg ? topology) {
              ${vmCfg.topology.id} = {
                guestType = "microvm";
                parent = config.topology.id;
                hardware.info = vmInfo vmCfg;

                interfaces = mkMerge (
                  flip map vmCfg.microvm.interfaces (i: {
                    ${i.id} = {
                      inherit (i) mac type;
                      virtual = true;
                      addresses = vmAddresses vmCfg;
                      network = microvmNetwork;
                      physicalConnections = [
                        {
                          node = config.topology.id;
                          interface = "microvms";
                          renderer.reverse = true;
                        }
                      ];
                    };
                  })
                );
              };
            }
          )
        );
      };
    };
}
