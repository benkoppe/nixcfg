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
    subnet = "10.1.0";
    externalInterface = "eno1";
  };

  my.service-vms = {
    adguard = {
      id = 1;
      config = {
        my.adguard.vHost = "adguard.thekoppe.com";
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
    resilio.id = 11;

    tang.id = 50;
  };
}
