{
  config,
  lib,
  ...
}:
{
  options.myNixOS.profiles.server.enable = lib.mkEnableOption "base system configuration";

  config = lib.mkIf config.myNixOS.profiles.server.enable {
    myNixOS = {
      profiles.base.enable = true;
    };

    security.pam.services.sshd.allowNullPassword = true;

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
  };
}
