{ self, ... }:
let
  vHost = "lldap.thekoppe.com";
in
{
  flake.clan.machines.vm-lldap =
    { config, ... }:
    {
      imports = with self.modules.nixos; [
        microvms_client
        caddy

        backup-b2
      ];

      my.caddy.virtualHosts = [
        {
          inherit vHost;
          port = config.services.lldap.settings.http_port;
        }
      ];

      my.backup-b2.lldap = {
        paths = [ "/var/lib/private/lldap" ];
        restartServices = [ "lldap" ];
      };

      microvm.volumes = [
        {
          image = "lldap-data.img";
          mountPoint = "/var/lib/private/lldap";
          size = 64;
        }
      ];

      clan.core.vars.generators =
        let
          mkSecret = description: {
            prompts.value = {
              inherit description;
              type = "hidden";
              persist = true;
            };
            share = true;
          };
        in
        {
          lldap-key-seed = mkSecret "Lldap key seed config";
          lldap-jwt-secret = mkSecret "Lldap jwt secret config";
          lldap-user-pass = mkSecret "Lldap admin pass config";
        };

      networking.firewall.allowedTCPPorts = [ 17170 ];

      networking.firewall.extraCommands = ''
        iptables -A INPUT -p tcp --dport 3890 -s 10.0.0.5 -j ACCEPT
        iptables -A INPUT -p tcp --dport 3890 -j DROP
      '';

      systemd.services.lldap =
        let
          getSecret = name: config.clan.core.vars.generators.${name}.files.value.path;
        in
        {
          serviceConfig.LoadCredential = [
            ''key-seed:${getSecret "lldap-key-seed"}''
            ''jwt-secret:${getSecret "lldap-jwt-secret"}''
            ''user-pass:${getSecret "lldap-user-pass"}''
          ];
        };
      services.lldap = {
        enable = true;
        silenceForceUserPassResetWarning = true;

        environment = {
          LLDAP_KEY_SEED_FILE = "%d/key-seed";
          LLDAP_JWT_SECRET_FILE = "%d/jwt-secret";
          LLDAP_LDAP_USER_PASS_FILE = "%d/user-pass";
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
    };
}
