{
  inputs,
  modulesPath,
  ...
}:
{
  imports = [
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
    systemd-boot.enable = true;
    efi.canTouchEfiVariables = true;
  };

  services.cloud-init = {
    enable = true;
    network.enable = true;
  };

  networking.useDHCP = false; # important (allegedly)
}
