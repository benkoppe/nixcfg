{ self, ... }:
let
  vHost = "lldap2.thekoppe.com";
in
{
  flake.modules.nixos.lldap = {
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
        lldap-key-seed = mkSecret "Lldap key seed config";
        lldap-jwt-secret = mkSecret "Lldap jwt secret config";
        lldap-user-pass = mkSecret "Lldap admin pass config";
      };

    my.service-vms.lldap.modules = [
      (
        { hostConfig, config, ... }:
        {
          imports = with self.modules.nixos; [
            caddy
          ];

          my.caddy.virtualHosts = [
            {
              inherit vHost;
              port = config.services.lldap.settings.http_port;
            }
          ];

          microvm.credentialFiles =
            let
              getSecret = name: hostConfig.clan.core.vars.generators.${name}.files.value.path;
            in
            {
              KEY_SEED = getSecret "lldap-key-seed";
              JWT_SECRET = getSecret "lldap-jwt-secret";
              USER_PASS = getSecret "lldap-user-pass";
            };

          systemd.services.lldap = {
            serviceConfig = {
              ImportCredential = [
                "KEY_SEED"
                "JWT_SECRET"
                "USER_PASS"
              ];
            };
          };

          networking.firewall.allowedTCPPorts = [ 17170 ];

          services.lldap = {
            enable = true;

            silenceForceUserPassResetWarning = true;
            environment = {
              LLDAP_KEY_SEED_FILE = "%d/KEY_SEED";
              LLDAP_JWT_SECRET_FILE = "%d/JWT_SECRET";
              LLDAP_LDAP_USER_PASS_FILE = "%d/USER_PASS";
            };

            settings = {
              http_url = "https://${vHost}";
              http_host = "0.0.0.0";
              http_port = 17170;

              ldap_host = "0.0.0.0";
              ldap_port = 3890;

              force_ldap_user_pass_reset = false;

              ldap_user_dn = "ldap-admin";
              ldap_user_email = "ldap-admin@thekoppe.com";

              ldap_base_dn = "dc=thekoppe,dc=com";

              database_url = "sqlite://./users.db?mode=rwc";
            };
          };
        }
      )
    ];
  };
}
