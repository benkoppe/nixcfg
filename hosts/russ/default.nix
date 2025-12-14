{
  self,
  inputs,
  config,
  modulesPath,
  ...
}:
{
  imports = [
    self.diskoConfigurations.simple-ext4
    (modulesPath + "/profiles/qemu-guest.nix")
    (modulesPath + "/installer/scan/not-detected.nix")
    ./hardware-configuration.nix
    ./display-config.nix
    ./home.nix
  ];

  services.qemuGuest.enable = true;

  myNixOS = {
    profiles.server.enable = true;
  };

  boot.loader = {
    grub = {
      enable = true;
      # no need to set devices, disko will add all devices that have a EF02 partition to the list already
      # devices = [ ];
      efiSupport = true;
      efiInstallAsRemovable = true;
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
      useDHCP = false;

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
