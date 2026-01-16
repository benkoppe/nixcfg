{
  self,
  config,
  lib,
  ...
}:
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
    adguard =
      let
        lancacheIp = "10.1.0.10";
      in
      {
        id = 1;
        config = {
          services.adguardhome.settings.filtering.rewrites =
            lib.pipe config.microvm.vms.lancache.config.config.services.lancache.domainIndex
              [
                (map (entry: entry.domains))
                lib.flatten
                (map (domain: {
                  inherit domain;
                  answer = lancacheIp;
                }))
              ];
        };
      };
    fastapi-dls.id = 2;
    vaultwarden.id = 3;
    lldap.id = 4;
    pocket-id.id = 5;
    cloudflared-dray.id = 6;
    garage.id = 7;
    forgejo.id = 8;
    komodo.id = 9;
    lancache.id = 10;
  };
}
