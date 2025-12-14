{
  inputs,
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
    profiles.server.colmenaSshAccess.enable = false;

    profiles.server.enable = true;
  };

  users.users.root = {
    openssh.authorizedKeys.keyFiles = [
      "${inputs.secrets}/pve/lxc-bootstrap-key.pub"
    ];

    hashedPassword = "";
  };

  services.qemuGuest.enable = true;

  boot.loader = {
    grub = {
      enable = true;
      # no need to set devices, disko will add all devices that have a EF02 partition to the list already
      # devices = [ ];
      efiSupport = true;
      efiInstallAsRemovable = true;
    };
  };

  services.cloud-init = {
    enable = true;
    network.enable = true;
  };

  networking.useDHCP = false; # important (allegedly)
}
