{ lib, ... }:
{
  flake.modules.nixos.komodo-periphery =
    { config, ... }:
    let
      cfg = config.my.komodo-periphery;
    in
    {
      options.my.komodo-periphery = {
        rootDirectory = lib.mkOption {
          type = lib.types.str;
          default = "/var/lib/komodo";
          description = "Root directory for Komodo periphery.";
        };
      };

      config = {
        clan.core.vars.generators =
          let
            mkSecret =
              description:
              {
                type ? "multiline-hidden",
                share ? false,
              }:
              {
                prompts.value = {
                  inherit description type;
                  persist = true;
                };
                inherit share;
              };
          in
          {
            komodo-periphery-env = mkSecret "Environment config for core + periphery" { share = true; };

            komodo-periphery-mounted-config = mkSecret "Mounted config values for periphery" { };
            komodo-periphery-syncs-key = mkSecret "Syncs decryption key for periphery" { type = "hidden"; };
          };

        virtualisation = {
          docker.enable = true;

          oci-containers =
            let
              getSecret = name: config.clan.core.vars.generators.${name}.files.value.path;
            in
            {
              backend = "docker";
              containers = {
                komodo-periphery = {
                  image = "ghcr.io/moghtech/komodo-periphery:latest";
                  pull = "always";
                  labels = {
                    "komodo.skip" = "";
                  };
                  environmentFiles = [
                    (getSecret "komodo-periphery-env")
                  ];
                  environment = {
                    # PERIPHERY_BIND_IP = "";
                    PERIPHERY_PORT = "8120";

                    PERIPHERY_ROOT_DIRECTORY = cfg.rootDirectory;
                    PERIPHERY_DISABLE_TERMINALS = "false";
                    PERIPHERY_SSL_ENABLED = "true";

                    PERIPHERY_INCLUDE_DISK_MOUNTS = "/etc/hostname";
                    # PERIPHERY_EXCLUDE_DISK_MOUNTS = "";

                    PERIPHERY_LOGGING_PRETTY = "true";
                    PERIPHERY_PRETTY_STARTUP_CONFIG = "true";
                  };
                  privileged = true;
                  volumes = [
                    "/var/run/docker.sock:/var/run/docker.sock"
                    "/proc:/proc"
                    "${cfg.rootDirectory}:${cfg.rootDirectory}"
                    "${getSecret "komodo-periphery-mounted-config"}:/config/config.toml"
                    "${getSecret "komodo-periphery-syncs-key"}:/config/komodo-syncs"
                  ];
                  cmd = [
                    "periphery"
                    "--config-path"
                    "/config/config.toml"
                  ];
                  # networks = [ "komodo-net" ];
                  ports = [ "8120:8120" ];
                };
              };
            };
        };
      };
    };
}
