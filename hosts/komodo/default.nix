{
  self,
  config,
  pkgs,
  ...
}:
let
  inherit (config.mySnippets) hostName hosts;
  inherit (hosts.${hostName}) vHost port;
in
{
  myNixOS = {
    profiles.proxmox-lxc.enable = true;
  };

  virtualisation = {
    docker.enable = true;

    oci-containers = {
      backend = "docker";
      containers =
        let
          inherit (config.age) secrets;
        in
        {
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
            environmentFiles = [ secrets.komodo-mongo-env.path ];
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
              secrets.komodo-mongo-env.path
              secrets.komodo-core-env.path
              secrets.komodo-periphery-env.path
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
              KOMODO_OIDC_PROVIDER = "https://${hosts.pocket-id.vHost}";

              KOMODO_GITHUB_OAUTH_ENABLED = "false";
              KOMODO_GOOGLE_OAUTH_ENABLED = "false";

              # KOMODO_AWS_ACCESS_KEY_ID_FILE = "";
              # KOMODO_AWS_SECRET_ACCESS_KEY_FILE = "";
            };
            volumes = [
              "/var/lib/komodo/backups:/backups"
            ];
            networks = [ "komodo-net" ];
          };

          komodo-periphery =
            let
              rootDirectory = "/etc/komodo";
            in
            {
              image = "ghcr.io/moghtech/komodo-periphery:latest";
              pull = "always";
              labels = {
                "komodo.skip" = "";
              };
              environmentFiles = [
                secrets.komodo-periphery-env.path
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
              ];
              networks = [ "komodo-net" ];
            };
        };
    };
  };

  age.secrets =
    let
      komodoSecrets = "${self.inputs.secrets}/services/komodo";
      common = secretFile: {
        file = secretFile;
      };
    in
    {
      komodo-mongo-env = common "${komodoSecrets}/mongo-environment.age";
      komodo-core-env = common "${komodoSecrets}/core-environment.age";
      komodo-periphery-env = common "${komodoSecrets}/periphery-environment.age";
    };

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

  networking = {
    nftables.enable = false;
    firewall.interfaces =
      let
        inherit (config.mySnippets) networks;
      in
      {
        ${networks.tailscale.deviceName}.allowedTCPPorts = [
          port
        ];

        #${networks.newt.deviceName}.allowedTCPPorts = [
        #port
        #];
      };
  };
}
