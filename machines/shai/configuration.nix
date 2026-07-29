{
  self,
  pkgs,
  config,
  ...
}:
{
  imports = with self.modules.nixos; [
    basics
    zfs-encrypt
    boot_limine
    tailgate

    ./microvms.nix
  ];

  my.tailgate.routes = [
    "10.2.0.0/24"
  ];

  services.vnstat.enable = true;

  my.networking.lan = {
    enable = true;
    interface = "eno1";
    address = "192.168.1.102";
  };

  clan.core.vars.generators.ups-secondary-password = {
    files.value.secret = true;
    script = "openssl rand -base64 48 > $out/value";
    runtimeInputs = with pkgs; [
      openssl
    ];
    share = true;
  };

  power.ups = {
    enable = true;
    mode = "netclient";

    upsmon = {
      monitor."apc-smart-620" = {
        system = "apc-smart-620@192.168.1.100";
        user = "secondary-client";
        passwordFile = config.clan.core.vars.generators.ups-secondary-password.files.value.path;
        type = "secondary";
      };

      settings.SHUTDOWNEXIT = 240;
    };
  };
}
