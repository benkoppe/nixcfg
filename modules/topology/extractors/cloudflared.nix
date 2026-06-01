{ inputs, ... }:
{
  flake.modules.nixos."topology/extractors/cloudflared" =
    { config, lib, ... }:
    let
      cfg = config.services.cloudflared or { };
      local = config.my.cloudflared or { };
      ingress = local.ingress or { };
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
          };
    };
}
