_: {
  flake.modules.nixos."topology/extractors/tang" =
    { config, lib, ... }:
    let
      cfg = config.services.tang or { };
    in
    {
      options.topology.extractors.localServices.tang.enable =
        lib.mkEnableOption "Tang topology extractor"
        // {
          default = true;
        };

      config = lib.mkIf (config.topology.extractors.localServices.tang.enable && (cfg.enable or false)) {
        topology.self.services.tang = {
          name = "Tang";
          icon = "services.not-available";
          details = {
            listen.text = lib.concatStringsSep "\n" (cfg.listenStream or [ ]);
            allow.text = lib.concatStringsSep "\n" (cfg.ipAddressAllow or [ ]);
          };
        };
      };
    };
}
