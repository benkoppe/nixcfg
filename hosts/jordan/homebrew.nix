{ config, ... }:
{
  myDarwin.programs.homebrew.enable = true;

  homebrew = {
    taps = builtins.attrNames config.nix-homebrew.taps;

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

        (greedy "figma")
        # (greedy "figma-agent")

        # Cybersecurity tools
        (greedy "proxyman")
        # (greedy "burp-suite")
        # (greedy "zap")

        # Productivity Tools
        # "raycast"
        (greedy "alfred")
        (greedy "jordanbaird-ice")
        (greedy "bettertouchtool")

        # Remote desktop
        # "vnc-viewer"
        (greedy "nomachine")
        (greedy "moonlight")
        (greedy "parsec")

        # Communication Tools - Examples (uncomment as needed)
        (greedy "discord")
        # "notion"
        # "slack"
        # "telegram"
        (greedy "zoom")

        # Utility Tools - Examples (uncomment as needed)
        # "syncthing"
        # "1password"
        # "rectangle"

        # Entertainment Tools - Examples (uncomment as needed)
        # "vlc"
        (greedy "steam")
        (greedy "altserver")

        # Work tools
        (greedy "microsoft-powerpoint")

        (greedy "macfuse")
      ];

    masApps = {
      # "wireguard" = 1451685025;
      Tailscale = 1475387142;
      Bitwarden = 1352778147;
    };
  };
}
