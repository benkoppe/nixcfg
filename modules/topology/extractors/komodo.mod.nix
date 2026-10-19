{ inputs, ... }:
{
  flake.modules.nixos."topology/extractors/komodo" =
    { config, lib, ... }:
    let
      containers = config.virtualisation.oci-containers.containers or { };
      core = containers.komodo-core or { };
      env = core.environment or { };
    in
    {
      options.topology.extractors.localServices.komodo.enable =
        lib.mkEnableOption "Komodo topology extractor"
        // {
          default = true;
        };

      config =
        lib.mkIf (config.topology.extractors.localServices.komodo.enable && (containers ? komodo-core))
          {
            topology.icons.services.komodo.file = inputs.selfhst-icons + "/svg/komodo.svg";

            topology.self.services.komodo = {
              name = "Komodo";
              icon = "services.komodo";
              info = env.KOMODO_HOST or "";
              details = {
                core.text = lib.concatStringsSep "\n" (core.ports or [ ]);
                database.text = env.KOMODO_DATABASE_ADDRESS or "";
                periphery.text = env.KOMODO_FIRST_SERVER_ADDRESS or "";
              };
            };
          };
    };
}
