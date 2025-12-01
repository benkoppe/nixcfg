{
  self,
  config,
  pkgs,
  lib,
  ...
}:
let
  cfg = config.services.forgejo;
  inherit (cfg) user group;
  inherit (cfg.settings) server;
  inherit (config.mySnippets) hostName;
  inherit (config.mySnippets.hosts.${hostName}) dataLocation vHost;
in
{
  imports = [ ./github2forgejo.nix ];

  myNixOS = {
    profiles.proxmox-lxc.enable = true;

    services.caddy =
      let
        port = server.HTTP_PORT;
      in
      {
        enable = false;
        networkDevices = with config.mySnippets.networks; [
          tailscale.deviceName
          newt.deviceName
        ];
        virtualHosts = [
          {
            inherit vHost port;
          }
        ];
      };
  };

  users = {
    users.${user}.uid = 1000;
    groups.${group}.gid = 1000;
  };

  environment.systemPackages = [
    pkgs.forgejo
  ];

  services.openssh.settings.AcceptEnv = lib.mkForce "GIT_PROTOCOL";

  services.forgejo = {
    enable = true;

    package = pkgs.forgejo;

    stateDir = dataLocation;
    database = {
      type = "sqlite3";
      path = "${config.services.forgejo.stateDir}/data/forgejo.db";
    };

    dump = {
      enable = true;
      interval = "04:31";
      file = "forgejo-dump";
      type = "zip";
      backupDir = "${config.services.forgejo.stateDir}/dump";
    };

    lfs = {
      enable = true;
      contentDir = "${config.services.forgejo.stateDir}/data/lfs";
    };

    settings =
      let
        description = "Ben's \"software\" forge";
      in
      {
        server = {
          DOMAIN = "${vHost}";
          ROOT_URL = "https://${server.DOMAIN}";
          HTTP_PORT = 3000;
          LANDING_PAGE = "explore";
          DISABLE_ROUTER_LOG = true;

          SSH_PORT = lib.head config.services.openssh.ports;
        };
        service.DISABLE_REGISTRATION = true;
        DEFAULT = {
          APP_NAME = "Forgejo";
          APP_SLOGAN = description;
        };
        repository = {
          DEFAULT_BRANCH = "main";
          DEFAULT_MERGE_STYLE = "rebase-merge";
          DEFAULT_REPO_UNITS = "repo.code, repo.issues, repo.pulls";

          ENABLE_PUSH_CREATE_ORG = true;
          ENABLE_PUSH_CREATE_USER = true;
          PREFERRED_LICENSES = "GPL-3.0,MIT,Apache-2.0";

          DISABLE_STARS = true;
        };
        "repository.upload" = {
          FILE_MAX_SIZE = 100;
          MAX_FILES = 10;
        };
        "repository.signing" = {
          FORMAT = "ssh";
          SIGNING_KEY = config.age.secrets."forgejo-signing-key.pub".path;
          SIGNING_NAME = "git.thekoppe.com Instance";
          SIGNING_EMAIL = "noreply-forgejo@thekoppe.com";
        };
        attachment.ALLOWED_TYPES = "*/*";
        cache.ENABLED = true;

        packages.ENABLED = false;
        mailer = {
          ENABLED = true;
          FROM = "Forgejo <koppe.development@gmail.com>";
          PROTOCOl = "smtp+starttls";
          SMTP_ADDR = "smtp.gmail.com";
          SMTP_PORT = 587;
          USER = "koppe.development@gmail.com";
        };

        other = {
          SHOW_FOOTER_TEMPLATE_LOAD_TIME = true;
          SHOW_FOOTER_VERSION = true;
        };
        session = {
          COOKIE_SECURE = true;
          SAME_SITE = "strict";
        };
        "ui.meta" = {
          AUTHOR = description;
          DESCRIPTION = description;
        };
      };

    secrets = {
      mailer.PASSWD = config.age.secrets.forgejo-smtp-pass.path;
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
      forgejo-smtp-pass = common "${self.inputs.secrets}/services/smtp/koppe-development-password.age";
      forgejo-signing-key = common "${self.inputs.secrets}/services/forgejo/server-signing-key.age";
      "forgejo-signing-key.pub" =
        common "${self.inputs.secrets}/services/forgejo/server-signing-key-pub.age";
    };

  networking.firewall.interfaces =
    let
      port = server.HTTP_PORT;
      inherit (config.mySnippets) networks;
    in
    {
      ${networks.tailscale.deviceName}.allowedTCPPorts = [
        port
      ];

      ${networks.newt.deviceName}.allowedTCPPorts = [
        port
      ];

      # ${networks.ldap.deviceName}.allowedTCPPorts = [ cfg.ldap_port ];
    };
}
