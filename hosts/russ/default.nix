{
  self,
  inputs,
  config,
  ...
}:
{
  imports = [
    self.diskoConfigurations.simple-ext4
    ./display-config.nix
    ./home.nix
  ];

  myNixOS = {
    profiles.proxmox-vm = {
      enable = true;
      diskInitType = "disko";
    };
  };

  mySnippets = {
    primaryUser = "russ";
  };

  users.users = {
    root.openssh.authorizedKeys.keyFiles = [
      "${inputs.secrets}/pve/russ-key.pub"
    ];

    russ = {
      isNormalUser = true;
      extraGroups = [ "wheel" ];
      openssh.authorizedKeys.keyFiles = [
        "${inputs.secrets}/pve/russ-key.pub"
      ];
      hashedPasswordFile = config.age.secrets.russ-user-password.path;
    };
  };

  age.secrets.russ-user-password = {
    file = "${inputs.secrets}/passwords/server-main.age";
    owner = "russ";
  };

  networking =
    let
      inherit (config.mySnippets.networks) tailscale;
    in
    {
      interfaces."ens18".ipv4.addresses = [
        {
          address = "${tailscale.prefix}.99";
          prefixLength = 24;
        }
      ];
      defaultGateway = {
        address = tailscale.gateway;
        interface = "ens18";
      };
      nameservers = [ "192.168.1.1" ];
    };
}
