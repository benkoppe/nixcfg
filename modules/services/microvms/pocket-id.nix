{ self, ... }:
let
  vHost = "pocket.thekoppe.com";
in
{
  flake.clan.machines.vm-pocket-id =
    { config, pkgs, ... }:
    {
      imports = with self.modules.nixos; [
        microvms_client

        caddy
        smtp-koppe-development

        backup-b2
      ];

      my.caddy.virtualHosts = [
        {
          inherit vHost;
          port = config.services.pocket-id.settings.PORT;
        }
      ];

      my.backup-b2.pocket-id = {
        paths = [ config.services.pocket-id.dataDir ];
        restartServices = [ "pocket-id" ];
      };

      microvm.volumes = [
        {
          image = "pocket-id-data.img";
          mountPoint = config.services.pocket-id.dataDir;
          size = 64;
        }
      ];

      clan.core.vars.generators =
        let
          owner = config.services.pocket-id.user;
          mkSecret = description: {
            prompts.value = {
              inherit description;
              type = "hidden";
              persist = true;
            };
            files.value.owner = owner;
            share = true;
          };
        in
        {
          pocket-ldap-pass = mkSecret "Pocket-id ldap service user password";
          pocket-encryption-key = {
            files.value = {
              secret = true;
              inherit owner;
            };
            script = ''openssl rand -base64 32 > $out/value'';
            runtimeInputs = with pkgs; [
              openssl
            ];
            share = true;
          };
          smtp-koppe-development.files.password.owner = owner;
        };

      services.pocket-id = {
        enable = true;

        dataDir = "/var/lib/pocket-id";
        settings =
          let
            getSecret = name: config.clan.core.vars.generators.${name}.files;
          in
          {
            ENCRYPTION_KEY_FILE = (getSecret "pocket-encryption-key").value.path;
            LDAP_BIND_PASSWORD_FILE = (getSecret "pocket-ldap-pass").value.path;
            SMTP_PASSWORD_FILE = (getSecret "smtp-koppe-development").password.path;

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
    };
}
