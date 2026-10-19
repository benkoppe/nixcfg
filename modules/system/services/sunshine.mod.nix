{
  flake.modules.nixos.sunshine = { config, ... }: {
    services.sunshine = {
      enable = true;
      autoStart = true;
      openFirewall = true;

      capSysAdmin = true;

      settings = {
        capture = "kms";
        encoder = "nvenc";
      };
    };

    hardware.uinput.enable = true;
    users.users.${config.system.primaryUser}.extraGroups = [ "uinput" ];
  };
}
