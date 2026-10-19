{ inputs, ... }:
{
  flake.modules.nixos."topology/extractors/garage" =
    { config, lib, ... }:
    let
      cfg = config.services.garage or { };
      settings = cfg.settings or { };
      vhosts = config.my.caddy.virtualHosts or [ ];
    in
    {
      options.topology.extractors.localServices.garage.enable =
        lib.mkEnableOption "Garage topology extractor"
        // {
          default = true;
        };

      config =
        lib.mkIf (config.topology.extractors.localServices.garage.enable && (cfg.enable or false))
          {
            topology.icons.services.garage.file = inputs.selfhst-icons + "/svg/garage.svg";

            topology.self.services.garage = {
              name = "Garage";
              icon = "services.garage";
              info = lib.concatStringsSep "\n" (map (vh: "https://${vh.vHost}") vhosts);
              details = {
                rpc.text = settings.rpc_bind_addr or "";
                s3.text = settings.s3_api.api_bind_addr or "";
                web.text = settings.s3_web.bind_addr or "";
                admin.text = settings.admin.api_bind_addr or "";
              };
            };
          };
    };
}
