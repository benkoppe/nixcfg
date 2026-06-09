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
    atuin.id = 12;
    zabbix.id = 13;

    samba.id = 20;

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

    vmToVmRules = [
      {
        name = "cloudflared-to-pocket-id";
        from = "cloudflared-dray";
        to = "pocket-id";
        proto = "tcp";
        ports = [ 443 ];
      }
      {
        name = "cloudflared-to-komodo";
        from = "cloudflared-dray";
        to = "komodo";
        proto = "tcp";
        ports = [ 443 ];
      }
      {
        name = "cloudflared-to-forgejo";
        from = "cloudflared-dray";
        to = "forgejo";
        proto = "tcp";
        ports = [ 443 ];
      }
      {
        name = "pocket-id-to-lldap";
        from = "pocket-id";
        to = "lldap";
        proto = "tcp";
        ports = [ 3890 ];
      }
    ];
  };
}
