{ self, ... }:
{
  imports = with self.modules.nixos; [
    microvms_host
    microvms_host_service-vms

    adguard
    tailgate
  ];

  my.service-vms = {
    adguard.id = 1;
    tailgate.id = 2;
  };
}
