{ self, ... }:
{
  flake.clan.machines.vm-bookstack =
    {
      pkgs,
      lib,
      config,
      ...
    }:
    let
      endpoint = config.my.public-endpoints.bookstack;

      bookstackPort = 8080;
      dataDir = config.services.bookstack.dataDir;
      dbName = "bookstack";
      dbUser = config.services.bookstack.user;
      dbBackupDir = "/var/backup/bookstack";
    in
    {
      imports = with self.modules.nixos; [
        microvms_client

        public-endpoints_caddy
        public-endpoints_cloudflared

        smtp-koppe-development

        zabbix-agent-caddy
        backup-b2
      ];

      my.public-endpoints.bookstack = {
        vHost = "docs.thekoppe.com";
        caddy.port = bookstackPort;
        cloudflared = { };
      };

      my.backup-b2 = {
        bookstack-data = {
          paths = [ dataDir ];
          restartServices = [ "phpfpm-bookstack" ];
        };

        bookstack-database = {
          paths = [ dbBackupDir ];
        };
      };

      microvm.volumes = [
        {
          image = "/tank0/microvms/bookstack/bookstack-data.img";
          mountPoint = dataDir;
          size = 1024 * 10; # 10 GiB
        }
        {
          image = "/tank0/microvms/bookstack/bookstack-mysql.img";
          mountPoint = "/var/lib/mysql";
          size = 1024 * 10;
        }
        {
          image = "/tank0/microvms/bookstack/bookstack-db-backup.img";
          mountPoint = dbBackupDir;
          size = 1024 * 2;
        }
      ];

      clan.core.vars.generators =
        let
          bookstackOwner = config.services.bookstack.user;
          smtpOwner = bookstackOwner;
        in
        {
          bookstack-app-key = {
            files.value = {
              secret = true;
              owner = bookstackOwner;
            };

            # Laravel expects the "base64:" prefix to be part of APP_KEY.
            script = ''
              printf 'base64:' > "$out/value"
              openssl rand -base64 32 >> "$out/value"
            '';

            runtimeInputs = [ pkgs.openssl ];
            share = true;
          };

          bookstack-oidc = {
            prompts.client-id = {
              description = "OIDC Client ID";
              persist = true;
            };
            prompts.client-secret = {
              description = "OIDC Client Secret";
              type = "hidden";
              persist = true;
            };
            files.client-id.owner = bookstackOwner;
            files.client-secret.owner = bookstackOwner;
            share = true;
          };

          smtp-koppe-development.files.password.owner = smtpOwner;
        };

      services.bookstack = {
        enable = true;

        hostname = endpoint.vHost;
        dataDir = "/var/lib/bookstack";
        maxUploadSize = "100M";

        settings = {
          APP_ENV = "production";
          APP_DEBUG = false;
          APP_URL = "https://${endpoint.vHost}";

          APP_KEY_FILE = config.clan.core.vars.generators.bookstack-app-key.files.value.path;

          DB_HOST = "localhost";
          DB_PORT = 3306;
          DB_DATABASE = dbName;
          DB_USERNAME = dbUser;

          # Local MariaDB user authenticated through unix_socket.
          DB_PASSWORD = "";

          # pocketid auth
          AUTH_METHOD = "oidc";
          AUTH_AUTO_INITIATE = true;
          OIDC_NAME = "Pocket ID";
          OIDC_DISPLAY_NAME_CLAIMS = "name";
          OIDC_FETCH_AVATAR = true;
          OIDC_CLIENT_ID_FILE = config.clan.core.vars.generators.bookstack-oidc.files.client-id.path;
          OIDC_CLIENT_SECRET_FILE = config.clan.core.vars.generators.bookstack-oidc.files.client-secret.path;
          OIDC_ISSUER = "https://pocket.thekoppe.com";
          OIDC_END_SESSION_ENDPOINT = true;
          OIDC_ISSUER_DISCOVER = true;

          # auto-groups from pocketid
          OIDC_USER_TO_GROUPS = true;
          OIDC_GROUPS_CLAIM = "groups";
          OIDC_ADDITIONAL_SCOPES = "groups";
          OIDC_REMOVE_FROM_GROUPS = true;

          MAIL_DRIVER = "smtp";
          MAIL_HOST = "smtp.gmail.com";
          MAIL_PORT = 587;
          MAIL_USERNAME = "koppe.development@gmail.com";
          MAIL_PASSWORD_FILE = config.clan.core.vars.generators.smtp-koppe-development.files.password.path;
          MAIL_ENCRYPTION = "tls";
          MAIL_FROM = "koppe.development@gmail.com";
          MAIL_FROM_NAME = "Koppe Family Docs";

          STORAGE_TYPE = "local_secure";
          SESSION_SECURE_COOKIE = true;
        };

        nginx = {
          listen = [
            {
              addr = "127.0.0.1";
              port = bookstackPort;
            }
          ];

          forceSSL = false;
          enableACME = false;

          locations."^~ /uploads/" = {
            root = "${config.services.bookstack.package}/public";
            tryFiles = "$uri $uri/ /index.php?$query_string";
          };
        };
      };

      services.mysql = {
        enable = true;
        package = pkgs.mariadb;

        ensureDatabases = [ dbName ];

        ensureUsers = [
          {
            name = dbUser;
            ensurePermissions = {
              "${dbName}.*" = "ALL PRIVILEGES";
            };
          }
        ];

        settings = {
          mysqld = {
            bind-address = "127.0.0.1";
            skip-name-resolve = true;

            # BookStack expects full Unicode support.
            character-set-server = "utf8mb4";
            collation-server = "utf8mb4_unicode_ci";
          };
        };
      };

      systemd.services.bookstack-database-backup = {
        description = "Back up the BookStack MariaDB database";

        after = [ "mysql.service" ];
        requires = [ "mysql.service" ];

        path = [
          config.services.mysql.package
          pkgs.coreutils
          pkgs.gzip
        ];

        serviceConfig = {
          Type = "oneshot";
          User = "root";
          Group = "root";
          UMask = "0077";
        };

        script = ''
          set -euo pipefail

          install -d -m 0700 ${dbBackupDir}

          tmp="${dbBackupDir}/.${dbName}.sql.gz.tmp"
          target="${dbBackupDir}/${dbName}.sql.gz"

          mariadb-dump \
            --single-transaction \
            --quick \
            --lock-tables=false \
            --default-character-set=utf8mb4 \
            --databases ${lib.escapeShellArg dbName} \
            | gzip -9 > "$tmp"

          mv "$tmp" "$target"
        '';
      };

      systemd.timers.bookstack-database-backup = {
        wantedBy = [ "timers.target" ];

        timerConfig = {
          OnCalendar = "daily";
          Persistent = true;
          RandomizedDelaySec = "30m";
          Unit = "bookstack-database-backup.service";
        };
      };

      # Ensure the first B2 run has a database dump available.
      systemd.services.bookstack-database-backup.wantedBy = [
        "multi-user.target"
      ];
    };
}
