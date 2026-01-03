{ self, ... }:
let
  dataDir = "/var/lib/vaultwarden/data";

  vHost = "vault3.thekoppe.com";
in
{
  flake.modules.nixos.vaultwarden =
    { pkgs, ... }:
    {

      clan.core.vars.generators.vaultwarden-admin = {
        prompts.password-input = {
          description = "Password for the vaultwarden admin";
          type = "hidden";
        };
        files.password-hash.secret = true;
        files.password-hash.owner = "microvm";
        script = ''
          cat $prompts/password-input | argon2 "$(openssl rand -base64 32)" -e -id -k 65540 -t 3 -p 4 > $out/password-hash
        '';
        share = true;
        runtimeInputs = with pkgs; [
          openssl
          libargon2
        ];
      };

      my.service-vms.vaultwarden.modules = [
        (
          { config, hostConfig, ... }:
          {
            imports = with self.modules.nixos; [
              caddy
              vaultwarden-snapshot
            ];

            my.caddy.virtualHosts = [
              {
                inherit vHost;
                port = config.services.vaultwarden.config.ROCKET_PORT;

                # fix bitwarden client error on /api/tasks 404 return
                # see https://github.com/dani-garcia/vaultwarden/pull/6557#issuecomment-3692818999
                extraConfig = [
                  ''
                    respond /api/tasks {"data":[]} 200
                  ''
                ];
              }
            ];

            microvm.volumes = [
              {
                image = "vaultwarden-data.img";
                mountPoint = config.services.vaultwarden.config.DATA_FOLDER;
                size = 64;
              }
            ];
            microvm.credentialFiles = {
              ADMIN_TOKEN = hostConfig.clan.core.vars.generators.vaultwarden-admin.files.password-hash.path;
              SMTP_PASS = hostConfig.clan.core.vars.generators.smtp-koppe-development.files.password.path;
            };

            systemd.services.vaultwarden = {
              serviceConfig.ImportCredential = [
                "ADMIN_TOKEN"
                "SMTP_PASS"
              ];
              environment = {
                ADMIN_TOKEN_FILE = "%d/ADMIN_TOKEN";
                SMTP_PASSWORD_FILE = "%d/SMTP_PASS";
              };
            };
            services.vaultwarden = {
              enable = true;
              dbBackend = "sqlite";

              config = {
                DOMAIN = "https://${vHost}";
                SIGNUPS_ALLOWED = false;
                DATA_FOLDER = dataDir;

                ROCKET_ADDRESS = "127.0.0.1";
                ROCKET_PORT = 8222;
                ROCKET_LOG = "critical";

                SMTP_HOST = "smtp.gmail.com";
                SMTP_PORT = 587;
                SMTP_SECURITY = "starttls";
                SMTP_FROM = "koppe.development@gmail.com";
                SMTP_USERNAME = "koppe.development@gmail.com";
                SMTP_FROM_NAME = "Koppe Vaultwarden";
              };
            };
          }
        )
      ];
    };
}
