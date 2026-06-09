{ self, ... }:
{
  imports = with self.modules.nixos; [
    microvms_host
    microvms_host_service-vms
  ];

  my.service-vms = {
    # adguard.id = 1;
    # vaultwarden.id = 3;
    # lldap.id = 4;
    # pocket-id.id = 5;
    cloudflared-luka.id = 6;
    # garage.id = 7;
    # forgejo.id = 8;

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
