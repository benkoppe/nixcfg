{
  perSystem = _: {
    terranix.terranixConfigurations = {
      wemby = {
        terraform.required_providers.proxmox = {
          source = "telmate/proxmox";
          version = ">=3.0.0";
        };

        provider.proxmox = {
          pm_api_url = "https://pve.thekoppe.com/api2/json";
          pm_api_token_id = "terraform-prov@pve!mytoken";
          pm_tls_insecure = true;
        };

        ostemplate = "pbs-130:backup/ct/240/2025-10-16T02:25:28Z";
        arch = "amd64";
        hostname = "wemby";
        target_node = "dray";
        vmid = 245;
        ip = "10.192.168.245/24";
        memory = 1024;
        cores = 2;

        network = {
          name = "eth_ts";
          bridge = "vxnetts";
          gw = "10.192.168.1";
          ip = "10.192.168.245/24";
        };
        rootfs = {
          storage = "local-zfs";
          size = "10G";
        };

        start = true;
        onboot = true;
        password = null;

        tags = "terranix"; # semicolon-separated

        unique = true;
        unprivileged = true;
      };
    };
  };
}
