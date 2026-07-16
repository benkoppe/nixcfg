{ self, ... }:
{
  flake.clan.machines.vm-lldap =
    { config, ... }:
    let
      endpoint = config.my.public-endpoints.lldap;
    in
    {
      imports = with self.modules.nixos; [
        microvms_client

        public-endpoints_caddy

        zabbix-agent-caddy
        backup-b2
      ];

      my.public-endpoints.lldap = {
        vHost = "lldap.thekoppe.com";
        caddy.port = config.services.lldap.settings.http_port;
      };

      my.backup-b2.lldap-data = {
        paths = [ "/var/lib/private/lldap" ];
        restartServices = [ "lldap" ];
        onCalendar = "*-*-* 01:00:00";
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

      networking.nftables.enable = true;
      networking.firewall = {
        allowedTCPPorts = [ 17170 ];
        extraInputRules = ''
          ip saddr { 10.1.0.5, 10.1.0.8 } tcp dport 3890 accept
        '';
      };

      systemd.services.lldap =
        let
          getSecret = name: config.clan.core.vars.generators.${name}.files.value.path;
        in
        {
          serviceConfig.LoadCredential = [
            "key-seed:${getSecret "lldap-key-seed"}"
            "jwt-secret:${getSecret "lldap-jwt-secret"}"
            "user-pass:${getSecret "lldap-user-pass"}"
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
          http_url = "https://${endpoint.vHost}";
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
