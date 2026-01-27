{
  self,
  ...
}:
{
  imports = with self.modules.nixos; [
    microvms_host
    microvms_host_service-vms
  ];

  my.microvms.network = {
    subnet = "10.2.0";
    externalInterface = "eno1";
  };

  my.service-vms = {
    adguard = {
      id = 1;
      config = {
        my.adguard.vHost = "shai.adguard.thekoppe.com";
      };
    };

    tang.id = 50;
  };
}
