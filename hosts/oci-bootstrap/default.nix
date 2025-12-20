{
  inputs,
  modulesPath,
  ...
}:
{
  imports = [ "${modulesPath}/virtualisation/oci-image.nix" ];

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

  users.users.nixos = {
    isNormalUser = true;
    extraGroups = [ "wheel" ];
    openssh.authorizedKeys.keyFiles = [
      "${inputs.secrets}/pve/lxc-bootstrap-key.pub"
    ];
  };

  services.cloud-init = {
    enable = true;
    network.enable = true;
  };
}
