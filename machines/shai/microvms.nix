{
  self,
  # config,
  # lib,
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
    # adguard =
    #   let
    #     lancacheIp = "10.1.0.10";
    #   in
    #   {
    #     id = 1;
    #     config = {
    #       services.adguardhome.settings.filtering.rewrites =
    #         lib.pipe config.microvm.vms.lancache.config.config.services.lancache.domainIndex
    #           [
    #             (map (entry: entry.domains))
    #             lib.flatten
    #             (map (domain: {
    #               inherit domain;
    #               answer = lancacheIp;
    #             }))
    #           ];
    #     };
    #   };
    tang.id = 50;
  };
}
