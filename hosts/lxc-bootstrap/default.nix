{
  self,
  ...
}:
{
  myNixOS = {
    profiles.proxmox-lxc.enable = true;
  };

  users.users.root = {
    openssh.authorizedKeys.keyFiles = [
      "${self.inputs.secrets}/pve/lxc-bootstrap-key.pub"
    ];

    hashedPassword = "";
  };
}
