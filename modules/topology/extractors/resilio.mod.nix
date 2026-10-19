{ inputs, ... }:
{
  flake.modules.nixos."topology/extractors/resilio" =
    { config, lib, ... }:
    let
      cfg = config.services.resilio or { };
      vhosts = config.my.caddy.virtualHosts or [ ];
    in
    {
      options.topology.extractors.localServices.resilio.enable =
        lib.mkEnableOption "Resilio Sync topology extractor"
        // {
          default = true;
        };

      config =
        lib.mkIf (config.topology.extractors.localServices.resilio.enable && (cfg.enable or false))
          {
            topology.icons.services.resilio.file = inputs.selfhst-icons + "/svg/resilio-sync.svg";

            topology.self.services.resilio = {
              name = "Resilio Sync";
              icon = "services.resilio";
              info = lib.concatStringsSep "\n" (map (vh: "https://${vh.vHost}") vhosts);
              details = {
                web.text = "${cfg.httpListenAddr or "0.0.0.0"}:${toString (cfg.httpListenPort or 9000)}";
                storage.text = cfg.storagePath or "";
                root.text = cfg.directoryRoot or "";
              };
            };
          };
    };
}
