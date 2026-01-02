let
  dataDir = "/var/lib/vaultwarden/data";

  vHost = "vault.thekoppe.com";
in
{
  flake.modules.nixos.vaultwarden =
    { config, pkgs, ... }:
    {
      clan.core.vars.generators = {
        vaultwarden-admin = {
          prompts.password-input = {
            description = "Password for the vaultwarden admin";
            type = "hidden";
          };
          files.password-hash.secret = true;
          files.password-hash.owner = "microvm";
          script = ''cat $prompts/password-input | argon2 "$(openssl rand -base64 32)" -e -id -k 65540 -t 3 -p 4 > $out/password-hash'';
          share = true;
          runtimeInputs = with pkgs; [
            openssl
            libargon2
          ];
        };
        koppe-development-smtp = {
          prompts.password = {
            description = "SMTP password for koppe.development@gmail.com";
            persist = true;
            type = "hidden";
          };
          files.password.owner = "microvm";
          share = true;
        };
      };

      my.service-vms.vaultwarden.modules =
        let
          cfg = config;
        in
        [
          (
            { config, ... }:
            {
              microvm.volumes = [
                {
                  image = "vaultwarden-data.img";
                  mountPoint = config.services.vaultwarden.config.DATA_FOLDER;
                  size = 64;
                }
              ];
              microvm.credentialFiles = {
                ADMIN_TOKEN = cfg.clan.core.vars.generators.vaultwarden-admin.files.password-hash.path;
                SMTP_PASS = cfg.clan.core.vars.generators.koppe-development-smtp.files.password.path;
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
