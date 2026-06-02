{ inputs, ... }:
{
  flake.modules.nixos."topology/extractors/pocket-id" =
    { config, lib, ... }:
    let
      cfg = config.services."pocket-id" or { };
      settings = cfg.settings or { };
    in
    {
      options.topology.extractors.localServices.pocket-id.enable =
        lib.mkEnableOption "Pocket ID topology extractor"
        // {
          default = true;
        };

      config =
        lib.mkIf (config.topology.extractors.localServices.pocket-id.enable && (cfg.enable or false))
          {
            topology.icons.services.pocket-id.file = inputs.selfhst-icons + "/svg/pocket-id.svg";

            topology.self.services.pocket-id = {
              name = "Pocket ID";
              icon = "services.pocket-id";
              info = settings.APP_URL or "";
              details = {
                listen.text = "0.0.0.0:${toString (settings.PORT or 1411)}";
                ldap.text = settings.LDAP_URL or "";
              };
            };
          };
    };
}
