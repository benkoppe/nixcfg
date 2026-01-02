{ self, ... }:
{
  imports = with self.modules.nixos; [
    microvms_host
    microvms_host_service-vms

    adguard
    tailgate
    vaultwarden
  ];

  my.service-vms = {
    adguard.id = 1;
    tailgate.id = 2;
    vaultwarden.id = 3;
  };
}
