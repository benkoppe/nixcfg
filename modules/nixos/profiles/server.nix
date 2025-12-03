{
  config,
  lib,
  inputs,
  ...
}:
{
  options.myNixOS.profiles.server = {
    enable = lib.mkEnableOption "base system configuration";

    colmenaSshAccess.enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable SSH access for Colmena management";
    };
  };

  config = lib.mkIf config.myNixOS.profiles.server.enable (
    lib.mkMerge [
      {
        myNixOS = {
          profiles.base.enable = true;
        };

        security.pam.services.sshd.allowNullPassword = true;

        users.users.root.hashedPassword = lib.mkDefault "";

        services.openssh = {
          enable = true;
          openFirewall = true;
          settings = {
            PermitRootLogin = "prohibit-password";
            PasswordAuthentication = false;
            PermitEmptyPasswords = false;
            KbdInteractiveAuthentication = false;
            UsePAM = true;
            X11Forwarding = true;
            PrintMotd = false;
            AcceptEnv = "LANG LC_*";
          };
        };
      }

      (lib.mkIf config.myNixOS.profiles.server.colmenaSshAccess.enable {
        users.users.root.openssh.authorizedKeys.keyFiles = [
          "${inputs.secrets}/pve/colmena.pub"
        ];
      })
    ]
  );
}
