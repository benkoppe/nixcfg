{ self, ... }:
{
  flake.modules.hjem.profile-full =
    { pkgs, osConfig, ... }:
    {
      imports = with self.modules.hjem; [
        ghostty

        zsh
        direnv
        atuin
        tmux-full
        ssh

        git
        gh
        lazygit

        nvim
      ];

      packages = with pkgs; [
        cachix
        sqlite

        # text/files
        aspell
        aspellDicts.en
        ripgrep
        fd
        tree
        jq
        bat
        sd

        # system
        btop
        dust
        watch

        # SDKs
        docker
        docker-compose

        # fonts # UI
        meslo-lgs-nf

        # media
        ffmpeg
        unrar
        hunspell

        # node
        nodejs
        pnpm
        bun
        deno

        # python
        python3
        virtualenv
        uv

        go

        # rust
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

        # security
        gnupg
        age
        age-plugin-yubikey
        libfido2

        # other
        fastfetch
      ];
    };
}
