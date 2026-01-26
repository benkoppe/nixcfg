{
  self,
  lib,
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

        services.adguardhome.settings.filtering.rewrites =
          lib.pipe
            self.clan.nixosConfigurations.dray.config.microvm.vms.lancache.config.config.services.lancache.domainIndex
            [
              (map (entry: entry.domains))
              lib.flatten
              (map (domain: {
                inherit domain;
                answer = "10.1.0.10";
              }))
            ];
      };
    };

    tang.id = 50;
  };
}
