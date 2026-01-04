{ lib, ... }:
{
  flake.modules.nixos.backup-b2 =
    { config, pkgs, ... }:
    let
      cfg = config.my.backup-b2;
    in
    {
      options.my.backup-b2 = lib.mkOption {
        type = lib.types.attrsOf (
          lib.types.submodule (
            { name, ... }:
            {
              options = {
                repository = lib.mkOption {
                  description = "Name of the repository within the B2 bucket";
                  type = lib.types.str;
                  default = name;
                };
                paths = lib.mkOption {
                  description = "Paths to backup";
                  type = lib.types.listOf lib.types.str;
                  default = [ ];
                };
                restartServices = lib.mkOption {
                  description = "Systemd services to stop during backup, then start";
                  type = lib.types.listOf lib.types.str;
                  default = [ ];
                };
              };
            }
          )
        );
      };

      config = {
        clan.core.vars.generators.rclone-resticblaze = {
          prompts.env-file = {
            description = "Environment file for Backblaze B2 resticblaze";
            type = "multiline";
            persist = true;
          };
          share = true;
        };
        clan.core.vars.generators.restic-password = {
          files.value.secret = true;
          script = ''openssl rand -base64 48 > $out/value'';
          runtimeInputs = with pkgs; [
            openssl
          ];
          share = true;
        };

        services.restic.backups =
          let
            mkStopCmd =
              services:
              lib.optionalString (
                services != [ ]
              ) "${pkgs.systemd}/bin/systemctl stop ${lib.concatStringsSep " " services}";

            mkStartCmd =
              services:
              lib.optionalString (
                services != [ ]
              ) "${pkgs.systemd}/bin/systemctl start ${lib.concatStringsSep " " services}";
          in
          lib.mapAttrs (_name: cfg: {
            repository = "s3:s3.us-west-004.backblazeb2.com/resticblaze/${cfg.repository}";
            inherit (cfg) paths;

            backupPrepareCommand = mkStopCmd cfg.restartServices;
            backupCleanupCommand = mkStartCmd cfg.restartServices;

            inhibitsSleep = true;
            initialize = true;

            timerConfig = {
              OnCalendar = "daily";
              Persistent = true;
            };

            pruneOpts = [
              "--keep-daily 7"
              "--keep-weekly 4"
              "--keep-monthly 3"
            ];

            extraBackupArgs = [
              "--cleanup-cache"
              "--compression max"
              "--no-scan"
            ];

            environmentFile = config.clan.core.vars.generators.rclone-resticblaze.files.env-file.path;
            passwordFile = config.clan.core.vars.generators.restic-password.files.value.path;
          }) cfg;
      };
    };
}
