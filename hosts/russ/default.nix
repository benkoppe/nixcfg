{
  config,
  self,
  pkgs,
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

  nix.settings = {
    sandbox = false;
    extra-substituters = [
      "https://nix-community.cachix.org"
      "https://cache.nixos.org"
      "https://install.determinate.systems"
    ];
    extra-trusted-public-keys = [
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
      "cache.flakehub.com-3:hJuILl5sVK4iKm86JzgdXW12Y2Hwd5G07qKtHTOcDCM="
    ];
    trusted-users = [
      "root"
      "@wheel"
      "builder"
    ];
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
