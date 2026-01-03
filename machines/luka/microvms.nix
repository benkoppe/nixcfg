{ self, ... }:
{
  imports = with self.modules.nixos; [
    microvms_host
    microvms_host_service-vms

    cloudflare-api

    adguard
    tailgate
    vaultwarden
    lldap
  ];

  my.service-vms = {
    adguard.id = 1;
    tailgate.id = 2;
    vaultwarden.id = 3;
    lldap.id = 4;
  };
}
