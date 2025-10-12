{
  config,
  lib,
  pkgs,
  self,
  ...
}:
{
  options.myDarwin.profiles.base.enable = lib.mkEnableOption "base system configuration";

  config = lib.mkIf config.myDarwin.profiles.base.enable {
    myDarwin = {
      programs.determinate.enable = true;

      system = {
        dock.enable = true;
        keyboard.enable = true;
        keybinds.enable = true;
        safari.enable = true;
        finder.enable = true;
        power.enable = true;
        screencapture.enable = true;
        trackpad.enable = true;
        unshittify.enable = true;
        windowmanager.enable = true;
      };
    };

    environment = {
      etc."nix-darwin".source = self;
      systemPackages = with pkgs; [ nh ];
    };

    networking.applicationFirewall.enable = true;

    security.pam.services.sudo_local = {
      enable = true;
      reattach = true;
      touchIdAuth = true;
    };

    system = {
      primaryUser = config.myDarwin.primaryUser;
      checks.verifyNixPath = false;
      stateVersion = 5;

      activationScripts.postActivation.text = ''
        # should allow us to avoid a logout/login cycle when changing settings
        sudo -u ${config.myDarwin.primaryUser} /System/Library/PrivateFrameworks/SystemAdministration.framework/Resources/activateSettings -u
      '';

      defaults.SoftwareUpdate.AutomaticallyInstallMacOSUpdates = false;
    };

    # stop login print in shell
    home-manager.sharedModules = [
      {
        home.file.".hushlogin".text = "";
      }
    ];

    # DEBUG SERVER
    # <https://sourcegraph.com/github.com/llvm/llvm-project@70906f0514826b5e64bd9354210ae836740c2053/-/blob/lldb/source/Plugins/Process/gdb-remote/GDBRemoteCommunication.cpp?L883>
    environment.variables.LLDB_DEBUGSERVER_PATH = "/Library/Developer/CommandLineTools/Library/PrivateFrameworks/LLDB.framework/Versions/A/Resources/debugserver";

    # Login window
    system.defaults.loginwindow = {
      DisableConsoleAccess = true;
      GuestEnabled = false;
    };

    # Menu bar
    system.defaults = {
      menuExtraClock.Show24Hour = false;
      menuExtraClock.ShowSeconds = false;

      controlcenter.BatteryShowPercentage = true;
      controlcenter.Bluetooth = true;
    };
  };
}
