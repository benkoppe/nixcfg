{
  self,
  config,
  lib,
  pkgs,
  ...
}:
{
  myNixOS = {
    profiles.proxmox-lxc.enable = true;

    services.caddy = {
      enable = true;
      domain = "thekoppe.com";
      subdomain = "lldap";
      port = config.services.lldap.settings.http_port;
    };
  };

  users = {
    users = {
      root = {
        openssh.authorizedKeys.keyFiles = [
          "${self.inputs.secrets}/pve/lxc-bootstrap-key.pub"
        ];
      };

      lldap = {
        isNormalUser = true;
        home = "/home/lldap";
        shell = pkgs.bash;
        group = "lldap";
      };
    };

    groups.lldap = { };
  };

  systemd.services.lldap.serviceConfig.DynamicUser = lib.mkForce false;

  services.lldap = {
    enable = true;

    environmentFile = config.age.secrets.lldap-env.path;

    silenceForceUserPassResetWarning = true;

    settings = {
      http_url = "https://lldap.thekoppe.com";
      http_host = "0.0.0.0";
      http_port = 17170;

      ldap_host = "0.0.0.0";
      ldap_port = 3890;

      jwt_secret_file = config.age.secrets.lldap-jwt.path;

      ldap_user_pass_file = config.age.secrets.lldap-admin-pass.path;
      force_ldap_user_pass_reset = false;

      ldap_user_dn = "ldap-admin";
      ldap_user_email = "ldap-admin@thekoppe.com";

      ldap_base_dn = "dc=thekoppe,dc=com";

      database_url = "sqlite://./users.db?mode=rwc";
    };
  };

  age.secrets =
    let
      secrets = "${self.inputs.secrets}/services/lldap";
      common = secretFile: {
        file = secretFile;
        owner = "lldap";
        group = "lldap";
        mode = "440";
      };
    in
    {
      lldap-jwt = common "${secrets}/jwt-secret.age";
      lldap-env = common "${secrets}/env-config.age";
      lldap-admin-pass = common "${secrets}/admin-password.age";
    };

  networking.firewall.interfaces =
    let
      cfg = config.services.lldap.settings;
      inherit (config.mySnippets) networks;
    in
    {
      ${networks.tailscale.deviceName}.allowedTCPPorts = [
        cfg.http_port
        80
        443
      ];

      ${networks.ldap.deviceName}.allowedTCPPorts = [ cfg.ldap_port ];
    };
}
