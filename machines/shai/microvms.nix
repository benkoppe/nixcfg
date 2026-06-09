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

  my.microvms.firewall = {
    enable = true;

    adminCidrs = [
      "192.168.1.0/24"
      "100.64.0.0/10"
    ];

    dnsServers = [ "192.168.1.1" ];

    allowVmInternet = true;
    logDenied = true;

    vmToVmRules = [ ];
  };
}
