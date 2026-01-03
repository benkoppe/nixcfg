{ self, ... }:
let
  vHost = "pocket.thekoppe.com";
in
{
  flake.modules.nixos.pocket-id =
    { pkgs, ... }:
    {
      clan.core.vars.generators =
        let
          mkSecret = description: {
            prompts.value = {
              inherit description;
              type = "hidden";
              persist = true;
            };
            files.value.owner = "microvm";
            share = true;
          };
        in
        {
          pocket-ldap-pass = mkSecret "Pocket-id ldap service user password";
          pocket-encryption-key = {
            files.value = {
              secret = true;
              owner = "microvm";
            };
            script = ''openssl rand -base64 32 > $out/value'';
            runtimeInputs = with pkgs; [
              openssl
            ];
          };
        };

      my.service-vms.pocket-id.modules = [
        (
          { config, hostConfig, ... }:
          {
            imports = with self.modules.nixos; [
              caddy
            ];

            my.caddy.virtualHosts = [
              {
                inherit vHost;
                port = config.services.pocket-id.settings.PORT;
              }
            ];

            microvm.volumes = [
              {
                image = "pocket-id-data.img";
                mountPoint = config.services.pocket-id.dataDir;
                size = 64;
              }
            ];
            microvm.credentialFiles = {
              SMTP_PASS = hostConfig.clan.core.vars.generators.smtp-koppe-development.files.password.path;
              LDAP_PASS = hostConfig.clan.core.vars.generators.pocket-ldap-pass.files.value.path;
              ENCRYPTION_KEY = hostConfig.clan.core.vars.generators.pocket-encryption-key.files.value.path;
            };

            systemd.services.pocket-id = {
              serviceConfig.ImportCredential = [
                "SMTP_PASS"
                "LDAP_PASS"
                "ENCRYPTION_KEY"
              ];
              environment = {
                SMTP_PASSWORD_FILE = "%d/SMTP_PASS";
                LDAP_BIND_PASSWORD_FILE = "%d/LDAP_PASS";
                ENCRYPTION_KEY_FILE = "%d/ENCRYPTION_KEY";
              };
            };

            services.pocket-id = {
              enable = true;

              dataDir = "/var/lib/pocket-id";
              settings = {
                APP_URL = "https://${vHost}";
                PORT = 1411;
                ANALYTICS_DISABLED = true;

                UI_CONFIG_DISABLED = true;

                SMTP_HOST = "smtp.gmail.com";
                SMTP_PORT = 587;
                SMTP_USER = "koppe.development@gmail.com";
                SMTP_FROM = "koppe.development@gmail.com";
                SMTP_TLS = "starttls";
                SMTP_SKIP_CERT_VERIFY = false;

                EMAIL_LOGIN_NOTIFICATION_ENABLED = true;
                EMAIL_ONE_TIME_ACCESS_AS_ADMIN_ENABLED = true;
                EMAIL_API_KEY_EXPIRATION_ENABLED = true;
                EMAIL_ONE_TIME_ACCESS_AS_UNAUTHENTICATED_ENABLED = false;

                LDAP_ENABLED = true;
                LDAP_URL = "ldap://lldap2.thekoppe.com:${toString 3890}";
                LDAP_BIND_DN = "uid=pocketid,ou=people,dc=thekoppe,dc=com";
                LDAP_BASE = "dc=thekoppe,dc=com";
                LDAP_USER_SEARCH_FILTER = "(&(objectClass=person)(|(memberof=cn=pocket_user,ou=groups,dc=thekoppe,dc=com)(memberof=cn=pocket_admin,ou=groups,dc=thekoppe,dc=com)))";
                LDAP_USER_GROUP_SEARCH_FILTER = "(objectClass=groupOfUniqueNames)";
                LDAP_SKIP_CERT_VERIFY = false;
                LDAP_SOFT_DELETE_USERS = false;

                LDAP_ATTRIBUTE_USER_UNIQUE_IDENTIFIER = "uuid";
                LDAP_ATTRIBUTE_USER_USERNAME = "uid";
                LDAP_ATTRIBUTE_USER_EMAIL = "mail";
                LDAP_ATTRIBUTE_USER_FIRST_NAME = "givenName";
                LDAP_ATTRIBUTE_USER_LAST_NAME = "sn";
                LDAP_ATTRIBUTE_USER_PROFILE_PICTURE = "avatar";
                LDAP_ATTRIBUTE_GROUP_MEMBER = "member";
                LDAP_ATTRIBUTE_GROUP_UNIQUE_IDENTIFIER = "uid";
                LDAP_ATTRIBUTE_GROUP_NAME = "cn";
                LDAP_ATTRIBUTE_ADMIN_GROUP = "pocket_admin";
              };
            };
          }
        )
      ];
    };
}
