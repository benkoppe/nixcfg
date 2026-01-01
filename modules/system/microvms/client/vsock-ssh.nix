{ lib, ... }:
{
  flake.modules.nixos."microvms_client_vsock-ssh" =
    { config, ... }:
    {
      users.mutableUsers = lib.mkDefault false;
      users.users.root.hashedPassword = "";

      microvm.vsock.cid = lib.mkDefault (config.my.microvms.index + 100000);
      microvm.vsock.ssh.enable = true;

      security.pam.services.sshd.allowNullPassword = true;

      services.openssh.settings = {
        PermitRootLogin = "yes";
        PermitEmptyPasswords = "yes";
        PasswordAuthentication = true;
      };
    };
}
