{ inputs, ... }:
{
  flake.modules.nixos."topology/extractors/cloudflared" =
    {
      config,
      lib,
      hostConfig ? null,
      ...
    }:
    let
      cfg = config.services.cloudflared or { };
      local = config.my.cloudflared or { };
      ingress = local.ingress or { };

      vmConfigs =
        if hostConfig == null then
          { }
        else
          lib.mapAttrs (
            vmName: vm:
            if vm.flake != null then vm.flake.nixosConfigurations.${vmName}.config else vm.config.config
          ) (hostConfig.microvm.vms or { });

      cloudflaredEndpoints =
        vmCfg:
        lib.filterAttrs (_: endpoint: endpoint ? cloudflared && endpoint.cloudflared != null) (
          vmCfg.my."public-endpoints" or { }
        );

      vmIsServed = vmCfg: cloudflaredEndpoints vmCfg != { } && vmCfg ? topology;

      servedVmConfigs = lib.filterAttrs (_: vmIsServed) vmConfigs;

      hasServedVms = servedVmConfigs != { };

      originNetwork = "${config.topology.id}-origins";
      originInterface = "origins";
      servedVmInterface = "${config.topology.id}";

      mkServedVmConnection = _vmName: vmCfg: {
        node = vmCfg.topology.id;
        interface = servedVmInterface;
        renderer.reverse = true;
      };

      mkServedVmInterface = _vmName: vmCfg: {
        ${vmCfg.topology.id}.interfaces.${servedVmInterface} = {
          virtual = true;
          type = "tunnel";
          network = originNetwork;
        };
      };
    in
    {
      options.topology.extractors.localServices.cloudflared.enable =
        lib.mkEnableOption "Cloudflared topology extractor"
        // {
          default = true;
        };

      config =
        lib.mkIf (config.topology.extractors.localServices.cloudflared.enable && (cfg.enable or false))
          {
            topology.icons.services.cloudflared.file = inputs.selfhst-icons + "/svg/cloudflare.svg";

            topology.self.services.cloudflared = {
              name = "Cloudflared";
              icon = "services.cloudflared";
              details.ingress.text =
                if ingress == { } then
                  "No ingress configured"
                else
                  lib.concatStringsSep "\n" (
                    lib.mapAttrsToList (host: value: "${host} -> ${value.service or ""}") ingress
                  );
            };

            topology.networks.${originNetwork} = lib.mkIf (hostConfig != null && hasServedVms) {
              name = "${config.networking.hostName} Cloudflared origins";
              style = {
                primaryColor = "#f38020";
                secondaryColor = null;
                pattern = "dotted";
              };
            };

            topology.self.interfaces.${originInterface} = lib.mkIf (hostConfig != null && hasServedVms) {
              virtual = true;
              type = "tunnel";
              network = originNetwork;
              physicalConnections = lib.mapAttrsToList mkServedVmConnection servedVmConfigs;
            };

            topology.nodes = lib.mkIf (hostConfig != null && hasServedVms) (
              lib.mkMerge (lib.mapAttrsToList mkServedVmInterface servedVmConfigs)
            );
          };
    };
}
