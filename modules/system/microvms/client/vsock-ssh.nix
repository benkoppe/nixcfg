{ lib, ... }:
{
  flake.modules.nixos."microvms_client_vsock-ssh" =
    { config, ... }:
    {
      users.mutableUsers = lib.mkDefault false;
      users.users.root.hashedPassword = "";

      microvm.vsock.cid = lib.mkDefault (config.my.microvm.id + 100000);
      microvm.vsock.ssh.enable = true;

      security.pam.services.sshd.allowNullPassword = true;

      services.openssh = {
        listenAddresses = [ ];
        openFirewall = true;

        settings = {
          PermitRootLogin = "yes";
          PermitEmptyPasswords = "yes";
          PasswordAuthentication = lib.mkForce true;
        };
      };
    };
}
