{ self, ... }:
{
  imports = with self.modules.nixos; [
    microvms_host
    microvms_host_service-vms
  ];

  my.service-vms = {
    adguard = {
      id = 1;
    };
  };
}
