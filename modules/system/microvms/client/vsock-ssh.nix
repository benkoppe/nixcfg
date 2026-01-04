{ lib, self, ... }:
{
  flake.modules.nixos."microvms_client_vsock-ssh" =
    { config, ... }:
    {
      users.mutableUsers = lib.mkDefault false;

      microvm.vsock.cid = lib.mkDefault (config.my.microvm.id + 100000);
      microvm.vsock.ssh.enable = true;

      users.users.root.openssh.authorizedKeys.keyFiles = [
        "${self}/vars/per-machine/luka/openssh/ssh.id_ed25519.pub/value"
      ];

      services.openssh = {
        openFirewall = false;
        listenAddresses = [ ];

        settings = {
          PermitRootLogin = "prohibit-password";
          PermitEmptyPasswords = false;
          PasswordAuthentication = false;
        };
      };
    };
}
