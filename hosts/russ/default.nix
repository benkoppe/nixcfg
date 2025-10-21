{
  self,
  modulesPath,
  ...
}:
{
  imports = [
    self.diskoConfigurations.simple-ext4
    (modulesPath + "/profiles/qemu-guest.nix")
    (modulesPath + "/installer/scan/not-detected.nix")
    ./hardware-configuration.nix
  ];

  myNixOS = {
    profiles.base.enable = true;
  };

  nixpkgs.hostPlatform = "x86_64-linux";

  services.openssh = {
    enable = true;

    openFirewall = true;
    settings = {
      PermitRootLogin = "prohibit-password";
      PasswordAuthentication = true;
      PermitEmptyPasswords = false;
      KbdInteractiveAuthentication = false;
      UsePAM = true;
      X11Forwarding = true;
      PrintMotd = false;
      AcceptEnv = "LANG LC_*";
    };
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

  security.pam.services.sshd.allowNullPassword = true;

  users.users.root.openssh.authorizedKeys.keyFiles = [
    "${self.inputs.secrets}/pve/russ-key.pub"
  ];

  networking = {
    useDHCP = false;

    interfaces."ens18".ipv4.addresses = [
      {
        address = "10.192.168.99";
        prefixLength = 24;
      }
    ];
    defaultGateway = {
      address = "10.192.168.1";
      interface = "ens18";
    };
    nameservers = [ "192.168.1.1" ];
  };

  system.stateVersion = "25.11";
}
