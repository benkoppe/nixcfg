{ self, ... }:
{
  flake.modules.darwin.macos-defaults =
    { config, ... }:
    {
      imports = with self.modules.darwin; [
        dock
        finder
        keybinds
        keyboard
        power
        safari
        screencapture
        trackpad
        unshittify
        windowmanager
      ];

      security.pam.services.sudo_local = {
        enable = true;
        reattach = true;
        touchIdAuth = true;
      };

      system = {
        activationScripts.postActivation.text = ''
          # should allow us to avoid a logout/login cycle when changing settings
          sudo -u ${config.system.primaryUser} /System/Library/PrivateFrameworks/SystemAdministration.framework/Resources/activateSettings -u
        '';
      };

      # stop login print in shell
      hjem.extraModules = [
        {
          files.".hushlogin".text = "";
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
