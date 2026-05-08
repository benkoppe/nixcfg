{ lib, ... }:
{
  flake.modules.hjem.zsh =
    { pkgs, ... }:
    {
      rum.programs.zsh = {
        enable = true;

        plugins = {
          oh-my-zsh.config = ''
            export ZSH="${pkgs.oh-my-zsh}/share/oh-my-zsh";
            plugins=(git)
            source "$ZSH/oh-my-zsh.sh"
          '';

          powerlevel10k.source = "${pkgs.zsh-powerlevel10k}/share/zsh-powerlevel10k/powerlevel10k.zsh-theme";

          powerlevel10k-config.source = "${lib.cleanSource ./.}/p10k.zsh";

          zsh-syntax-highlighting.source = "${pkgs.zsh-syntax-highlighting}/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh";

          zsh-autosuggestions.source = "${pkgs.zsh-autosuggestions}/share/zsh-autosuggestions/zsh-autosuggestions.zsh";

          zsh-history-substring-search.source = "${pkgs.zsh-history-substring-search}/share/zsh-history-substring-search/zsh-history-substring-search.zsh";
        };

        initConfig = ''

          unsetopt AUTO_CD
          cdpath=(~/Developer)

          autoload -Uz compinit
          compinit

          bindkey '^Y' autosuggest-accept

          bindkey '^[[A' history-substring-search-up
          bindkey '^P' history-substring-search-up
          bindkey '^[[B' history-substring-search-down
          bindkey '^N' history-substring-search-down

          if [[ -f /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh ]]; then
            . /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
            . /nix/var/nix/profiles/default/etc/profile.d/nix.sh
          fi

          # Define variables for directories
          export PATH=$HOME/.pnpm-packages/bin:$HOME/.pnpm-packages:$PATH
          export PATH=$HOME/.npm-packages/bin:$HOME/bin:$PATH
          export PATH=$HOME/.local/share/bin:$PATH

          # nvim is my editor
          export ALTERNATE_EDITOR=""
          export EDITOR="vi" 
          export VISUAL="nvim"

          # Always color ls and group directories
          alias ls='ls --color=auto'

          # Use bitwarden desktop ssh agent
          export SSH_AUTH_SOCK="$HOME/Library/Containers/com.bitwarden.desktop/Data/.bitwarden-ssh-agent.sock"
        '';
      };
    };
}
