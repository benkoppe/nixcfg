{ self, ... }:
{
  flake.clan.machines.vm-rustdesk = { lib, config, ... }: {
    imports = with self.modules.nixos; [
      microvms_client
    ];

    microvm.volumes = [
      {
        image = "/tank0/microvms/rustdesk/rustdesk-data.img";
        mountPoint = "/var/lib/private/rustdesk";
        size = 512;
      }
    ];

    microvm.mem = 256;

    services.rustdesk-server = {
      enable = true;
      openFirewall = true;

      signal = {
        enable = true;
      };

      relay.enable = false;
    };

    # normally rustdesk errors out without relay servers set, this fixes that
    systemd.services.rustdesk-signal.serviceConfig.ExecStart =
      lib.mkForce "${config.services.rustdesk-server.package}/bin/hbbs";
  };
}
