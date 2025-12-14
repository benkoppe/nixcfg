{
  inputs,
  ...
}:
{
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
}
