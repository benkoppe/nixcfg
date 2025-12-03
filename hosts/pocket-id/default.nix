{
  self,
  config,
  inputs,
  ...
}:
let
  inherit (config.mySnippets) hostName hosts;
  inherit (hosts.${hostName}) vHost;
in
{
  myNixOS = {
    profiles.proxmox-lxc.enable = true;
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
      SMTP_PASSWORD_FILE = config.age.secrets.pocket-smtp-pass.path;

      EMAIL_LOGIN_NOTIFICATION_ENABLED = true;
      EMAIL_ONE_TIME_ACCESS_AS_ADMIN_ENABLED = true;
      EMAIL_API_KEY_EXPIRATION_ENABLED = true;
      EMAIL_ONE_TIME_ACCESS_AS_UNAUTHENTICATED_ENABLED = false;

      LDAP_ENABLED = true;
      LDAP_URL =
        let
          inherit (self.nixosConfigurations.lldap.config.services.lldap.settings) ldap_port;
        in
        "ldap://${config.mySnippets.networks.ldap.prefix}.${toString hosts.lldap.suffix}:${toString ldap_port}";
      LDAP_BIND_DN = "uid=pocketid,ou=people,dc=thekoppe,dc=com";
      LDAP_BASE = "dc=thekoppe,dc=com";
      LDAP_USER_SEARCH_FILTER = "(&(objectClass=person)(|(memberof=cn=pocket_user,ou=groups,dc=thekoppe,dc=com)(memberof=cn=pocket_admin,ou=groups,dc=thekoppe,dc=com)))";
      LDAP_USER_GROUP_SEARCH_FILTER = "(objectClass=groupOfUniqueNames)";
      LDAP_SKIP_CERT_VERIFY = false;
      LDAP_SOFT_DELETE_USERS = false;
      LDAP_BIND_PASSWORD_FILE = config.age.secrets.pocket-ldap-pass.path;

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

  age.secrets =
    let
      common = secretFile: {
        file = secretFile;
        owner = config.services.pocket-id.user;
        inherit (config.services.pocket-id) group;
        mode = "440";
      };
    in
    {
      pocket-smtp-pass = common "${inputs.secrets}/services/smtp/koppe-development-password.age";
      pocket-ldap-pass = common "${inputs.secrets}/services/pocket-id/ldap-bind-password.age";
    };

  networking.firewall.interfaces =
    let
      cfg = config.services.pocket-id.settings;
      inherit (config.mySnippets) networks;
    in
    {
      ${networks.tailscale.deviceName}.allowedTCPPorts = [
        cfg.PORT
      ];

      ${networks.newt.deviceName}.allowedTCPPorts = [
        cfg.PORT
      ];

      # ${networks.ldap.deviceName}.allowedTCPPorts = [ cfg.ldap_port ];
    };
}
