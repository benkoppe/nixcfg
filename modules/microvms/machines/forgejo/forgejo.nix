{ self, lib, ... }:
let
  vHost = "git.thekoppe.com";

  dataDir = "/var/lib/forgejo";
in
{
  flake.clan.machines.vm-forgejo =
    { config, pkgs, ... }:
    let
      cfg = config.services.forgejo;
    in
    {
      imports = with self.modules.nixos; [
        microvms_client

        caddy
        smtp-koppe-development
        github2forgejo

        backup-b2
      ];

      microvm.mem = 4096; # 2 GiB

      my.caddy.virtualHosts = [
        {
          inherit vHost;
          port = cfg.settings.server.HTTP_PORT;
        }
      ];

      my.backup-b2.forgejo = {
        paths = [ config.services.forgejo.stateDir ];
        restartServices = [ "forgejo" ];
      };

      microvm.volumes = [
        {
          image = "forgejo-data.img";
          mountPoint = dataDir;
          size = 1024 * 50; # 50 GiB
        }
      ];

      clan.core.vars.generators = {
        forgejo-signing-key = {
          files."key" = {
            secret = true;
            owner = cfg.user;
          };
          files."key.pub" = {
            secret = true;
            owner = cfg.user;
          };
          runtimeInputs = [
            pkgs.coreutils
            pkgs.openssh
          ];
          script = ''
            ssh-keygen -t ed25519 -N "" -C "" -f "$out"/key
          '';
          share = true;
        };
      };
      clan.core.vars.generators.smtp-koppe-development.files.password.owner = cfg.user;

      services.openssh.settings.AcceptEnv = lib.mkForce [ "GIT_PROTOCOL" ];
      services.openssh.openFirewall = lib.mkForce true;

      services.forgejo = {
        enable = true;

        package = pkgs.forgejo;

        stateDir = dataDir;
        database = {
          type = "sqlite3";
          path = "${config.services.forgejo.stateDir}/data/forgejo.db";
        };

        lfs = {
          enable = true;
          contentDir = "${config.services.forgejo.stateDir}/data/lfs";
        };

        settings =
          let
            description = "Ben's \"software\" forge";
          in
          {
            server = rec {
              DOMAIN = "${vHost}";
              ROOT_URL = "https://${DOMAIN}";
              HTTP_PORT = 3000;
              LANDING_PAGE = "explore";
              DISABLE_ROUTER_LOG = true;

              SSH_PORT = lib.head config.services.openssh.ports;
            };
            service.DISABLE_REGISTRATION = true;
            DEFAULT = {
              APP_NAME = "Forgejo";
              APP_SLOGAN = description;
            };
            repository = {
              DEFAULT_BRANCH = "main";
              DEFAULT_MERGE_STYLE = "rebase-merge";
              DEFAULT_REPO_UNITS = "repo.code, repo.issues, repo.pulls";

              ENABLE_PUSH_CREATE_ORG = true;
              ENABLE_PUSH_CREATE_USER = true;
              PREFERRED_LICENSES = "GPL-3.0,MIT,Apache-2.0";

              DISABLE_STARS = true;
            };
            "repository.upload" = {
              FILE_MAX_SIZE = 100;
              MAX_FILES = 10;
            };
            "repository.signing" = {
              FORMAT = "ssh";
              SIGNING_KEY = config.clan.core.vars.generators."forgejo-signing-key".files."key.pub".path;
              SIGNING_NAME = "git.thekoppe.com Instance";
              SIGNING_EMAIL = "noreply-forgejo@thekoppe.com";
            };
            attachment.ALLOWED_TYPES = "*/*";
            cache.ENABLED = true;

            packages.ENABLED = false;
            mailer = {
              ENABLED = true;
              FROM = "Forgejo <koppe.development@gmail.com>";
              PROTOCOl = "smtp+starttls";
              SMTP_ADDR = "smtp.gmail.com";
              SMTP_PORT = 587;
              USER = "koppe.development@gmail.com";
            };

            other = {
              SHOW_FOOTER_TEMPLATE_LOAD_TIME = true;
              SHOW_FOOTER_VERSION = true;
            };
            session = {
              COOKIE_SECURE = true;
              SAME_SITE = "strict";
            };
            "ui.meta" = {
              AUTHOR = description;
              DESCRIPTION = description;
            };
          };

        secrets = {
          mailer.PASSWD = config.clan.core.vars.generators.smtp-koppe-development.files.password.path;
        };
      };
    };
}
