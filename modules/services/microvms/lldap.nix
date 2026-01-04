{ self, lib, ... }:
let
  vHost = "lldap2.thekoppe.com";
in
{
  flake.clan.machines.vm-lldap =
    { config, ... }:
    {
      imports = with self.modules.nixos; [
        microvms_client
        caddy
      ];

      my.caddy.virtualHosts = [
        {
          inherit vHost;
          port = config.services.lldap.settings.http_port;
        }
      ];

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
            files.value.owner = "lldap";
            share = true;
          };
        in
        {
          lldap-key-seed = mkSecret "Lldap key seed config";
          lldap-jwt-secret = mkSecret "Lldap jwt secret config";
          lldap-user-pass = mkSecret "Lldap admin pass config";
        };

      networking.firewall.allowedTCPPorts = [ 17170 ];

      users = {
        users.lldap = {
          isNormalUser = true;
          group = "lldap";
        };

        groups.lldap = { };
      };

      systemd.services.lldap.serviceConfig.DynamicUser = lib.mkForce false;

      services.lldap = {
        enable = true;
        silenceForceUserPassResetWarning = true;

        settings =
          let
            getSecret = name: config.clan.core.vars.generators.${name}.files.value.path;
          in
          {
            key_seed_file = getSecret "lldap-key-seed";
            jwt_secret_file = getSecret "lldap-jwt-secret";
            ldap_user_pass_file = getSecret "lldap-user-pass";

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
