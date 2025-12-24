{
  pkgs,
  inputs,
  config,
  ...
}:
{

  services.displayManager = {
    enable = true;
    sddm = {
      enable = true;
      wayland.enable = true;
    };
  };
  services.desktopManager.plasma6.enable = true;
  environment.plasma6.excludePackages = with pkgs.kdePackages; [
    elisa
    khelpcenter
    krdp
  ];

  hardware.graphics.enable = true;
  services.xserver.videoDrivers = [ "nvidia" ];
  hardware.nvidia = {
    open = true;

    modesetting.enable = true;
    nvidiaSettings = true;

    powerManagement.enable = true;
  };

  environment.systemPackages = with pkgs; [
    # kdePackages.konsole
    # kdePackages.dolphin
    # kdePackages.okular
    # kdePackages.gwenview
    # kdePackages.kate
    # kdePackages.kcalc
    # kdePackages.libksysguard
    # kdePackages.konversation
    # kdePackages.breeze-icons
    chromium
  ];

  programs.chromium = {
    enable = true;
    enablePlasmaBrowserIntegration = true;
  };

  # programs.firefox = {
  #   enable = true;
  # };

  home-manager.users.${config.mySnippets.primaryUser} = {
    imports = [
      inputs.plasma-manager.homeModules.plasma-manager
    ];

    programs.plasma = {
      enable = true;

      hotkeys.commands = {
        launch-ghostty = {
          name = "Launch Ghostty";
          key = "Meta+Return";
          command = "ghostty";
        };
        launch-brave = {
          name = "Launch Brave";
          key = "Meta+B";
          command = "brave";
        };
      };

      input = {
        keyboard = {
          repeatDelay = 250;
          repeatRate = 40;
        };
      };

      krunner.activateWhenTypingOnDesktop = false;

      kscreenlocker = {
        # appearance.showMediaControls = false;
        # appearance.wallpaper = "${config.wallpaper}";
        autoLock = false;
        timeout = 0;
      };

      kwin = {
        virtualDesktops = {
          number = 5;
          rows = 1;
        };
      };

      overrideConfig = true;

      powerdevil = {
        AC = {
          autoSuspend.action = "nothing";
          dimDisplay.enable = true;
          powerButtonAction = "shutDown";
          turnOffDisplay.idleTimeout = "never";
        };
      };

      session = {
        general.askForConfirmationOnLogout = false;
        sessionRestore.restoreOpenApplicationsOnLogin = "startWithEmptySession";
      };

      shortcuts = {
        ksmserver = {
          "Lock Session" = [
            "Screensaver"
            "Ctrl+Alt+L"
          ];
          "LogOut" = [
            "Ctrl+Alt+Q"
          ];
        };

        kwin = {
          # "KrohnkiteMonocleLayout" = [ ];
          "Switch to Desktop 1" = "Meta+1";
          "Switch to Desktop 2" = "Meta+2";
          "Switch to Desktop 3" = "Meta+3";
          "Switch to Desktop 4" = "Meta+4";
          "Switch to Desktop 5" = "Meta+5";
          # "Switch to Desktop 6" = "Meta+6";
          # "Switch to Desktop 7" = "Meta+7";
          "Window Close" = "Meta+Q";
          "Window Fullscreen" = "Meta+F";
          # "Window Move Center" = "Ctrl+Alt+C";
        };

        "services/org.kde.dolphin.desktop"."_launch" = "Meta+F";
      };

      spectacle = {
        shortcuts = {
          captureEntireDesktop = "";
          captureRectangularRegion = "";
          launch = "";
          recordRegion = "Meta+Shift+R";
          recordScreen = "Meta+Ctrl+R";
          recordWindow = "";
        };
      };

      workspace = {
        enableMiddleClickPaste = false;
        clickItemTo = "select";
        tooltipDelay = 1;
        # wallpaper = "${config.wallpaper}";
      };

      configFile = {
        kdeglobals = {
          General = {
            # BrowserApplication = "brave-browser.desktop";
          };
          Icons = {
            # Theme = "Tela-circle-dark";
          };
          KDE = {
            AnimationDurationFactor = 0;
          };
        };
        klipperrc.General.MaxClipItems = 1000;
      };
    };
  };
}
