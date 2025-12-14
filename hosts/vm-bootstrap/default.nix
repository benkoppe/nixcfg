{
  inputs,
  ...
}:
{
  myNixOS = {
    profiles.server.colmenaSshAccess.enable = false;

    profiles.proxmox-vm.enable = true;
  };

  users.users.root = {
    openssh.authorizedKeys.keyFiles = [
      "${inputs.secrets}/pve/lxc-bootstrap-key.pub"
    ];

    hashedPassword = "";
  };

  services.cloud-init = {
    enable = true;
    network.enable = true;
  };
}
