{ self, ... }:
{
  imports = with self.modules.nixos; [
    microvms_host
    microvms_host_service-vms
  ];

  my.microvms.network = {
    subnet = "10.1.0";
    externalInterface = "eno1";
  };

  my.service-vms = {
    # kde.id = 1;
    tailgate = {
      id = 1;
      config = {
        my.tailgate.routes = [
          "10.1.0.0/24"
          "10.1.1.0/24"
        ];
      };
    };
    fastapi-dls.id = 2;
  };
}
