{ pkgs, ... }:
{
  system.defaults.dock.persistent-apps = [
    {
      spacer = {
        small = false;
      };
    }
    { app = "/Applications/Brave Browser.app"; }
    # { app = "${pkgs.spotify}/Applications/Spotify.app"; }
    { app = "/Applications/Discord.app"; }
    {
      spacer = {
        small = false;
      };
    }
    { app = "${pkgs.ghostty-bin}/Applications/Ghostty.app"; }
    # { app = "/Volumes/Apps/Manual/Xcode.app"; }
    { app = "/System/Applications/System Settings.app"; }
    {
      spacer = {
        small = false;
      };
    }
  ];

  homebrew = {
    casks =
      let
        greedy = name: {
          inherit name;
          greedy = true;
        };
      in
      [
        # Development Tools
        # "docker"
        (greedy "visual-studio-code")
        (greedy "xcodes-app")
        (greedy "arduino-ide")

        # Creative
        (greedy "figma")
        # (greedy "figma-agent")
        (greedy "calibre")

        # Cybersecurity tools
        (greedy "proxyman")
        # (greedy "burp-suite")
        # (greedy "zap")

        # Productivity Tools
        # "raycast"
        (greedy "alfred")
        # (greedy "jordanbaird-ice")
        (greedy "bettertouchtool")
        (greedy "keyboardcleantool")

        # Remote desktop
        # "vnc-viewer"
        (greedy "nomachine")
        (greedy "moonlight")
        (greedy "parsec")

        # Social
        (greedy "discord")
        # "notion"
        # "slack"
        # "telegram"
        (greedy "zoom")
        (greedy "spotify")
        (greedy "steam")

        # Productivity Apps
        (greedy "microsoft-powerpoint")
        (greedy "obsidian")
        # "vlc"

        # Other
        (greedy "macfuse")
        (greedy "altserver")
      ];

    masApps = {
      # "wireguard" = 1451685025;
      # Tailscale = 1475387142;
      Bitwarden = 1352778147;
    };
  };
}
