{
  config,
  lib,
  self,
  ...
}:
{
  options.myDarwin.system.power.enable = lib.mkEnableOption "sensible power configuration";

  config = lib.mkIf config.myDarwin.system.power.enable {
    system.defaults.CustomUserPreferences = {
      "com.apple.screensaver" = {
        # Require password immediately after sleep or screen saver begins
        askForPassword = true;
        askForPasswordDelay = 0;
      };
    };

    # time in minutes before sleep
    power.sleep = {
      computer = 60;
      display = 30;
    };

    # system.activationScripts.pmset.text = ''
    #   sudo /usr/bin/pmset -b sleep 10 displaysleep 5 disksleep 10
    #   sudo /usr/bin/pmset -c sleep 0 displaysleep 0  disksleep 0
    # '';
  };
}
