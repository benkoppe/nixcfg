{ self, ... }:
let
  vHost = "komodo2.thekoppe.com";
  port = 9120;
  rootDirectory = "/var/lib/komodo";
in
{
  flake.clan.machines.vm-komodo =
    { pkgs, config, ... }:
    {
      imports = with self.modules.nixos; [
        microvms_client
        caddy
      ];

      my.caddy.virtualHosts = [
        {
          inherit vHost;
          inherit port;
        }
        {
          vHost = "nexterm.thekoppe.com";
          port = 6989;
        }
      ];

      microvm.mem = 4096;

      microvm.volumes = [
        {
          image = "/tank0/microvms/komodo/docker-data.img";
          mountPoint = "/var/lib/docker";
          size = 50 * 1024;
        }
        {
          image = "/tank0/microvms/komodo/komodo-data.img";
          mountPoint = "/var/lib/komodo";
          size = 5 * 1024;
        }
      ];

      systemd.services.init-komodo-network = {
        description = "Create the network bridge for komodo.";
        after = [ "network.target" ];
        wantedBy = [ "multi-user.target" ];
        serviceConfig.Type = "oneshot";
        script = ''
          # Put a true at the end to prevent getting non-zero return code, which will crash the whole service.
          check=$(${pkgs.docker}/bin/docker network ls | grep "komodo-net" || true)
          if [ -z "$check" ]; then
            ${pkgs.docker}/bin/docker network create komodo-net
          else
              echo "komodo-net already exists in docker"
          fi
        '';
      };

      clan.core.vars.generators =
        let
          mkSecret =
            description:
            {
              type ? "multiline-hidden",
            }:
            {
              prompts.value = {
                inherit description type;
                persist = true;
              };
              share = true;
            };
        in
        {
          komodo-mongo-env = mkSecret "Environment config for core + mongo" { };
          komodo-periphery-env = mkSecret "Environment config for core + periphery" { };

          komodo-core-mounted-config = mkSecret "Mounted config values for core" { };
          komodo-periphery-mounted-config = mkSecret "Mounted config values for periphery" { };

          komodo-periphery-syncs-local = mkSecret "Syncs decryption key for 'local' periphery" {
            type = "hidden";
          };
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
              mongo = {
                image = "mongo:latest";
                pull = "always";
                labels = {
                  "komodo.skip" = "";
                };
                cmd = [
                  "--quiet"
                  "--wiredTigerCacheSizeGB"
                  "0.25"
                ];
                environmentFiles = [ (getSecret "komodo-mongo-env") ];
                volumes = [
                  "mongo-data:/data/db"
                  "mongo-config:/data/configdb"
                ];
                networks = [ "komodo-net" ];
              };

              komodo-core = {
                image = "ghcr.io/moghtech/komodo-core:latest";
                pull = "always";
                labels = {
                  "komodo.skip" = "";
                };
                dependsOn = [ "mongo" ];
                ports = [ "${toString port}:9120" ];
                environmentFiles = [
                  (getSecret "komodo-mongo-env")
                  (getSecret "komodo-periphery-env")
                ];
                environment = {
                  KOMODO_HOST = "https://${vHost}";
                  KOMODO_TITLE = "Komodo";
                  KOMODO_FIRST_SERVER = "https://komodo-periphery:8120";
                  KOMODO_DISABLE_CONFIRM_DIALOG = "true";

                  KOMODO_DATABASE_ADDRESS = "mongo:27017";

                  KOMODO_MONITORING_INTERVAL = "15-sec";
                  KOMODO_RESOURCE_POLL_INTERVAL = "15-min";

                  KOMODO_JWT_TTL = "1-day";

                  KOMODO_LOCAL_AUTH = "false";
                  KOMODO_DISABLE_USER_REGISTRATION = "false";
                  KOMODO_ENABLE_NEW_USERS = "false";
                  KOMODO_DISABLE_NON_ADMIN_CREATE = "false";
                  KOMODO_TRANSPARENT_MODE = "false";

                  KOMODO_LOGGING_PRETTY = "true";
                  KOMODO_PRETTY_STARTUP_CONFIG = "true";

                  KOMODO_OIDC_ENABLED = "true";
                  KOMODO_OIDC_PROVIDER = "https://pocket.thekoppe.com";

                  KOMODO_GITHUB_OAUTH_ENABLED = "false";
                  KOMODO_GOOGLE_OAUTH_ENABLED = "false";

                  # KOMODO_AWS_ACCESS_KEY_ID_FILE = "";
                  # KOMODO_AWS_SECRET_ACCESS_KEY_FILE = "";
                };
                volumes = [
                  "${rootDirectory}/backups:/backups"
                  "${getSecret "komodo-core-mounted-config"}:/config/config.toml"
                ];
                networks = [ "komodo-net" ];
              };

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
                  PERIPHERY_ROOT_DIRECTORY = rootDirectory;
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
                  "${rootDirectory}:${rootDirectory}"
                  "${getSecret "komodo-periphery-mounted-config"}:/config/config.toml"
                  "${getSecret "komodo-periphery-syncs-local"}:/config/komodo-syncs"
                ];
                cmd = [
                  "periphery"
                  "--config-path"
                  "/config/config.toml"
                ];
                networks = [ "komodo-net" ];
              };
            };
          };
      };
    };
}
