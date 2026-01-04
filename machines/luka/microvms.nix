{ self, ... }:
{
  imports = with self.modules.nixos; [
    microvms_host
    microvms_host_service-vms
    microvms_host_service-vms-2

    cloudflare-api
    smtp-koppe-development

    # adguard
    # tailgate
    # vaultwarden
    # lldap
    # pocket-id
  ];

  # my.service-vms = {
  #   adguard.id = 1;
  #   tailgate.id = 2;
  #   # vaultwarden.id = 3;
  #   lldap.id = 4;
  #   pocket-id.id = 5;
  # };

  my.service-vms-2 = {
    vaultwarden.id = 3;
  };
}
