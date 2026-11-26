{ lib, ... }:
{
  flake.modules.hjem.zsh =
    { config, pkgs, ... }:
    {
      rum.programs.zsh = {
        enable = true;

        plugins = {
          oh-my-zsh.config = ''
            export ZSH="${pkgs.oh-my-zsh}/share/oh-my-zsh";
            plugins=(git)
            source "$ZSH/oh-my-zsh.sh"
          '';

          # Prompt only: in `zsh -c`, p10k's `setopt monitor` backgrounds the command (e.g. Rex resumes).
          powerlevel10k.config = ''
            if [[ -z $ZSH_EXECUTION_STRING ]]; then
              source "${pkgs.zsh-powerlevel10k}/share/zsh-powerlevel10k/powerlevel10k.zsh-theme"
              source "${lib.cleanSource ./.}/p10k.zsh"
            fi
          '';

          zsh-syntax-highlighting.source = "${pkgs.zsh-syntax-highlighting}/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh";

          zsh-autosuggestions.source = "${pkgs.zsh-autosuggestions}/share/zsh-autosuggestions/zsh-autosuggestions.zsh";

          zsh-history-substring-search.source = "${pkgs.zsh-history-substring-search}/share/zsh-history-substring-search/zsh-history-substring-search.zsh";
        };

        initConfig = ''

          unsetopt AUTO_CD
          cdpath=(~/Developer)

          autoload -Uz compinit
          compinit

          # Bind autosuggest widgets once (on the first prompt) instead of
          # re-wrapping every widget before each prompt, which costs ~50ms.
          ZSH_AUTOSUGGEST_MANUAL_REBIND=1

          bindkey '^Y' autosuggest-accept

          bindkey '^[[A' history-substring-search-up
          bindkey '^P' history-substring-search-up
          bindkey '^[[B' history-substring-search-down
          bindkey '^N' history-substring-search-down

          # Define variables for directories
          export PATH=$HOME/.pnpm-packages/bin:$HOME/.pnpm-packages:$PATH
          export PATH=$HOME/.npm-packages/bin:$HOME/bin:$PATH
          export PATH=$HOME/.local/share/bin:$PATH

          # Always color ls and group directories
          alias ls='ls --color=auto'

          ${config.shellAliasesInit}
        '';
      };
    };
}
