# NOTE: these are 'backups' in vaultwarden world.
# for clarity, because only one is kept, they're referred to here as 'snapshots'
{ lib, ... }:
let
  snapDir = "/var/lib/vaultwarden/snapshot";
in
{
  flake.modules.nixos.vaultwarden-snapshot =
    { config, pkgs, ... }:
    let
      dataDir = config.services.vaultwarden.config.DATA_FOLDER;
      user = config.users.users.vaultwarden.name;
      group = config.users.groups.vaultwarden.name;
    in
    {
      systemd = {
        services.vaultwarden-snapshot = {
          description = "Take a snapshot of the current Vaultwarden state";
          environment = {
            DATA_FOLDER = dataDir;
            SNAP_FOLDER = snapDir;
          };
          path = with pkgs; [ sqlite ];
          # if both services are started at the same time, vaultwarden fails with "database is locked"
          before = [ "vaultwarden.service" ];
          serviceConfig = {
            SyslogIdentifier = "vaultwarden-snapshot";
            Type = "oneshot";
            User = lib.mkDefault user;
            Group = lib.mkDefault group;
            ExecStart = "${pkgs.bash}/bin/bash ${./snapshot.sh}";
          };
          wantedBy = [ "multi-user.target" ];
        };

        timers.vaultwarden-snapshot = {
          description = "Timed vaultwarden snapshot";
          timerConfig = {
            OnCalendar = lib.mkDefault "23:00";
            Persistent = "true";
            Unit = "vaultwarden-snapshot.service";
          };
          wantedBy = [ "multi-user.target" ];
        };

        tmpfiles.settings = {
          "10-vaultwarden".${snapDir}.d = {
            inherit user group;
            mode = "0770";
          };
        };
      };
    };
}
