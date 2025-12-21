{
  inputs,
  config,
  lib,
  ...
}:
let
  inherit (config.mySnippets) hostName;
  inherit (config.mySnippets.hosts.${hostName}) vHost mntDir;
  port = 9000;
in
{
  myNixOS = {
    profiles.proxmox-lxc.enable = true;

    services.caddy = {
      enable = true;

      virtualHosts = [
        {
          inherit vHost port;
        }
      ];
    };
  };

  users = {
    users.minio = {
      uid = lib.mkForce 1000;
      group = "minio";
      isSystemUser = true;
    };
    groups.minio = {
      gid = lib.mkForce 1000;
    };
  };

  services.minio = {
    enable = true;

    certificatesDir = "${mntDir}/certs";
    configDir = "${mntDir}/config";
    dataDir = [ "${mntDir}/data" ];

    region = "us-east-1";
    browser = false;

    listenAddress = ":${toString port}";
    rootCredentialsFile = config.age.secrets.minio-root-credentials.path;
  };

  age.secrets = {
    minio-root-credentials.file = "${inputs.secrets}/services/minio/root-credentials.age";
  };
}
