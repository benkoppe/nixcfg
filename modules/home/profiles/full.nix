{
  config,
  lib,
  pkgs,
  ...
}:
{
  options.myHome.profiles.full.enable = lib.mkEnableOption "full home configuration";

  config = lib.mkIf config.myHome.profiles.full.enable {
    myHome = {
      profiles.base.enable = true;

      programs = {
        zsh.enable = true;
        ssh.enable = true;

        ghostty.enable = true;
        lazygit.enable = true;
        nvim.enable = true;
        tmux.enablePlugins = true;
        devenv.enable = true;

        yazi.enable = true;
      };
    };

    programs.tealdeer = {
      enable = true;
      settings.updates.auto_update = true;
    };

    home.packages =
      (with pkgs; [
        # General packages for development and system management
        aspell
        aspellDicts.en
        btop
        sqlite
        cachix

        dust
        sd

        # Text/data tools
        jq
        ripgrep
        fd
        tree

        # CLI power tools
        bat

        # Cloud tools and SDKs
        docker
        docker-compose

        # Fonts & UI
        dejavu_fonts
        ffmpeg
        font-awesome
        hack-font
        noto-fonts
        noto-fonts-color-emoji
        jetbrains-mono
        meslo-lgs-nf

        # Media
        ffmpeg
        unrar
        hunspell
        # spotify

        # Node.js dev tools
        nodejs_24
        pnpm

        # Python
        python3
        virtualenv
        uv

        # Go
        go

        # Rust
        cargo-deny
        cargo-expand
        cargo-fuzz
        cargo-nextest
        evcxr
        taplo
        cargo
        clippy
        rustc
        rustfmt

        # Security / crypto
        gnupg
        age
        age-plugin-yubikey
        libfido2

        # Silly
        fastfetch
      ])
      ++ lib.optionals pkgs.stdenv.hostPlatform.isDarwin (
        with pkgs;
        [
          dockutil

          alt-tab-macos

          # docker daemon without docker desktop
          colima

          raycast
        ]
      );
  };
}
