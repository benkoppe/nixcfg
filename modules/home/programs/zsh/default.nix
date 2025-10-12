{
  config,
  lib,
  pkgs,
  ...
}:
{
  options.myHome.programs.zsh.enable = lib.mkEnableOption "zsh shell";

  config = lib.mkIf config.myHome.programs.zsh.enable {
    home.packages = [
      pkgs.zsh-powerlevel10k
    ];

    programs.zsh = {
      enable = true;
      autocd = false;
      cdpath = [ "~/Projects" ];
      plugins = [
        {
          name = "powerlevel10k";
          src = pkgs.zsh-powerlevel10k;
          file = "share/zsh-powerlevel10k/powerlevel10k.zsh-theme";
        }
        {
          name = "powerlevel10k-config";
          src = lib.cleanSource ./.;
          file = "p10k.zsh";
        }
      ];
      oh-my-zsh = {
        enable = true;
        plugins = [ "git" ];
      };
      syntaxHighlighting.enable = true;
      autosuggestion.enable = true;
      enableCompletion = true;
      historySubstringSearch = {
        enable = true;
        searchUpKey = [
          "^[[A"
          "^P"
        ];
        searchDownKey = [
          "^[[B"
          "^N"
        ];
      };
      initContent = ''
        # accept completions with <Ctrl> + y
        bindkey '^Y' autosuggest-accept

        if [[ -f /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh ]]; then
          . /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
          . /nix/var/nix/profiles/default/etc/profile.d/nix.sh
        fi

        # Define variables for directories
        export PATH=$HOME/.pnpm-packages/bin:$HOME/.pnpm-packages:$PATH
        export PATH=$HOME/.npm-packages/bin:$HOME/bin:$PATH
        export PATH=$HOME/.local/share/bin:$PATH

        # Remove history data we don't want to see
        # export HISTIGNORE="pwd:ls:cd"

        # Ripgrep alias
        alias search=rg -p --glob '!node_modules/*'  $@

        # nvim is my editor
        export ALTERNATE_EDITOR=""
        export EDITOR="vi" 
        export VISUAL="vi"

        # nix shortcuts
        shell() {
            nix-shell '<nixpkgs>' -A "$1"
        }

        # pnpm is a javascript package manager
        alias pn=pnpm
        alias px=pnpx

        # Always color ls and group directories
        alias ls='ls --color=auto'
      '';
    };
  };
}
