{ self, ... }:
{
  imports = with self.modules.nixos; [
    microvms_host
    microvms_host_service-vms
  ];

  my.service-vms = {
    adguard.id = 1;
    tailgate = {
      id = 2;
      config = {
        my.tailgate.routes = [
          "10.0.0.0/24"
        ];
      };
    };
    vaultwarden.id = 3;
    lldap.id = 4;
    pocket-id.id = 5;
    cloudflared-luka.id = 6;
    garage.id = 7;
    forgejo.id = 8;
  };
}
