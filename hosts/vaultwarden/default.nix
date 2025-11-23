{
  self,
  config,
  pkgs,
  lib,
  ...
}:
let
  user = config.users.users.vaultwarden.name;
  group = config.users.groups.vaultwarden.name;
  dataDir = "/var/lib/vaultwarden/data";
in
{
  myNixOS = {
    profiles.proxmox-lxc.enable = true;

    services.nginx =
      let
        port = config.services.vaultwarden.config.ROCKET_PORT;
      in
      {
        enable = true;
        domain = "thekoppe.com";
        subdomain = "vault";
        inherit port;
        proxyWebsockets = true;
      };
  };

  users.users.root.openssh.authorizedKeys.keyFiles = [
    "${self.inputs.secrets}/pve/lxc-bootstrap-key.pub"
  ];

  environment.systemPackages = [
    pkgs.vaultwarden
  ];

  services.vaultwarden = {
    enable = true;

    dbBackend = "sqlite";

    config = {
      DOMAIN =
        let
          cfg = config.myNixOS.services.nginx;
        in
        "https://${cfg.subdomain}.${cfg.domain}";
      SIGNUPS_ALLOWED = false;
      DATA_FOLDER = dataDir;

      ADMIN_TOKEN_FILE = config.age.secrets.vaultwarden-admin-token.path;

      ROCKET_ADDRESS = "127.0.0.1";
      ROCKET_PORT = 8222;
      ROCKET_LOG = "critical";

      SMTP_HOST = "smtp.gmail.com";
      SMTP_PORT = 587;
      SMTP_SECURITY = "starttls";
      SMTP_FROM = "koppe.development@gmail.com";
      SMTP_USERNAME = "koppe.development@gmail.com";
      SMTP_FROM_NAME = "Koppe Vaultwarden";
      SMTP_PASSWORD_FILE = config.age.secrets.vaultwarden-smtp-pass.path;
    };
  };

  age.secrets =
    let
      common = secretFile: {
        file = secretFile;
        owner = user;
        inherit group;
        mode = "440";
      };
    in
    {
      vaultwarden-smtp-pass = common "${self.inputs.secrets}/services/smtp/koppe-development-password.age";
      vaultwarden-admin-token = common "${self.inputs.secrets}/services/vaultwarden/admin-token.age";
    };
}
// (
  let
    backupDir = "/var/backup/vaultwarden";
  in
  {
    systemd = {
      services.backup-vaultwarden = {
        description = "Backup vaultwarden";
        environment = {
          DATA_FOLDER = dataDir;
          BACKUP_FOLDER = backupDir;
        };
        path = with pkgs; [ sqlite ];
        # if both services are started at the same time, vaultwarden fails with "database is locked"
        before = [ "vaultwarden.service" ];
        serviceConfig = {
          SyslogIdentifier = "backup-vaultwarden";
          Type = "oneshot";
          User = lib.mkDefault user;
          Group = lib.mkDefault group;
          ExecStart = "${pkgs.bash}/bin/bash ${./backup.sh}";
        };
        wantedBy = [ "multi-user.target" ];
      };

      timers.backup-vaultwarden = {
        description = "Backup vaultwarden on time";
        timerConfig = {
          OnCalendar = lib.mkDefault "23:00";
          Persistent = "true";
          Unit = "backup-vaultwarden.service";
        };
        wantedBy = [ "multi-user.target" ];
      };

      tmpfiles.settings = {
        "10-vaultwarden".${backupDir}.d = {
          inherit user group;
          mode = "0770";
        };
      };
    };
  }
)
