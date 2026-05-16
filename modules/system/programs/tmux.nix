{ self, ... }:
{
  flake.modules.hjem.tmux-full = {
    imports = with self.modules.hjem; [
      tmux
      tmux-plugins
      tmux-sessionizer
    ];
  };

  flake.modules.hjem.tmux =
    { pkgs, ... }:
    {
      packages = [
        pkgs.tmux
      ];

      xdg.config.files."tmux/tmux.conf".text = /* bash */ ''
        set  -g default-terminal "tmux-256color"
        set  -g base-index      1
        setw -g pane-base-index 1

        set -g status-keys emacs
        set -g mode-keys   emacs

        # rebind main key: C-space
        unbind C-b
        set -g prefix C-space
        bind -N "Send the prefix key through to the application" \
          C-space send-prefix

        set -g cursor-style bar

        set  -g mouse             on
        set  -g focus-events      on
        setw -g aggressive-resize on
        setw -g clock-mode-style  12
        set  -s escape-time       0
        set  -g history-limit     50000

        # set background color of selected window in status line to a slightly different green
        # changed on computer from colour48
        set -g window-status-current-style bg=colour42,fg=black

        # fix wrong shell with tmux-sensible bug
        set -gu default-command
        set -g default-shell "$SHELL"

        # -----------------------------------------------------------------------------
        # Key bindings
        # -----------------------------------------------------------------------------

        # Unbind default keys
        unbind '"'
        unbind %

        # Split panes, vertical or horizontal
        bind-key - split-window -v
        bind-key | split-window -h

        # Move around panes with vim-like bindings (h,j,k,l)
        # bind-key -n M-k select-pane -U
        # bind-key -n M-h select-pane -L
        # bind-key -n M-j select-pane -D
        # bind-key -n M-l select-pane -R

        # Smart pane switching with awareness of Vim splits.
        # This is copy paste from https://github.com/christoomey/vim-tmux-navigator
        #is_vim="ps -o state= -o comm= -t '#{pane_tty}' \
          #| grep -iqE '^[^TXZ ]+ +(\\S+\\/)?g?(view|n?vim?x?)(diff)?$'"
        #bind-key -n 'C-h' if-shell "$is_vim" 'send-keys C-h'  'select-pane -L'
        #bind-key -n 'C-j' if-shell "$is_vim" 'send-keys C-j'  'select-pane -D'
        #bind-key -n 'C-k' if-shell "$is_vim" 'send-keys C-k'  'select-pane -U'
        #bind-key -n 'C-l' if-shell "$is_vim" 'send-keys C-l'  'select-pane -R'
        #tmux_version='$(tmux -V | sed -En "s/^tmux ([0-9]+(.[0-9]+)?).*/\1/p")'
        #if-shell -b '[ "$(echo "$tmux_version < 3.0" | bc)" = 1 ]' \
          #"bind-key -n 'C-\\' if-shell \"$is_vim\" 'send-keys C-\\'  'select-pane -l'"
        #if-shell -b '[ "$(echo "$tmux_version >= 3.0" | bc)" = 1 ]' \
          #"bind-key -n 'C-\\' if-shell \"$is_vim\" 'send-keys C-\\\\'  'select-pane -l'"

        bind-key -T copy-mode-vi 'C-h' select-pane -L
        bind-key -T copy-mode-vi 'C-j' select-pane -D
        bind-key -T copy-mode-vi 'C-k' select-pane -U
        bind-key -T copy-mode-vi 'C-l' select-pane -R
        bind-key -T copy-mode-vi 'C-\' select-pane -l

        # enable vim copy mode
        setw -g mode-keys vi
        # TODO: make vim copy mode usable by rebinding commands to match vim
      '';
    };

  flake.modules.hjem.tmux-plugins =
    { pkgs, lib, ... }:
    let
      plugins = with pkgs.tmuxPlugins; [
        vim-tmux-navigator
        sensible
        yank
        session-wizard
        fuzzback
        cpu
        jump
        extrakto
        tmux-thumbs
        pain-control
        tmux-which-key
        better-mouse-mode
        {
          plugin = continuum;
          extraConfig = ''
            set -g @continuum-restore 'on'
          '';
        }
        {
          plugin = resurrect;
          extraConfig = ''
            set -g @resurrect-dir '$HOME/.cache/tmux/resurrect'
            set -g @resurrect-capture-pane-contents 'on'
            set -g @resurrect-pane-contents-area 'visible'
          '';
        }
      ];

      tmuxPluginName =
        p: if lib.isAttrs p && p ? plugin then p.plugin.pname or p.plugin.name else p.pname or p.name;

      tmuxPluginRtp = p: if lib.isAttrs p && p ? plugin then p.plugin.rtp else p.rtp;

      tmuxPluginExtraConfig = p: if lib.isAttrs p && p ? extraConfig then p.extraConfig else "";

      tmuxPluginConfig =
        plugins:
        ''
          # ---------------------
        ''
        + lib.concatMapStringsSep "\n\n" (p: ''
          # ${tmuxPluginName p}
          # ---------------------
          ${tmuxPluginExtraConfig p}
          run-shell ${tmuxPluginRtp p}
        '') plugins
        + ''
          # ---------------------
        '';
    in
    {
      xdg.config.files."tmux/tmux.conf".text = lib.mkBefore ''
        ${tmuxPluginConfig plugins}
      '';
    };

  flake.modules.hjem.tmux-sessionizer =
    { pkgs, lib, ... }:
    let
      tmux-sessionizer-source = pkgs.fetchFromGitHub {
        owner = "ThePrimeagen";
        repo = "tmux-sessionizer";
        rev = "7edf8211e36368c29ffc0d2c6d5d2d350b4d729b";
        hash = "sha256-4QGlq/cLbed7AZhQ3R1yH+44gmgp9gSzbiQft8X5NwU=";
      };

      tmux-sessionizer-shims = /* bash */ ''
        # --- tmux-sessionizer shims (run before upstream script) ----------------------

        # Portable "absolute directory" resolver:
        # - If given a directory path (including ".", "..", "../.."), returns its abs dir.
        # - If given a file path, returns the abs dir of the file's parent.
        # - Tolerates non-existent segments when realpath(1) is available via -m.
        _ts_abs_dir() {
          local p="$1"

          # Prefer realpath if available
          if command -v realpath >/dev/null 2>&1; then
            if [[ -d "$p" || "$p" == "." || "$p" == ".." || "$p" == */. || "$p" == */.. ]]; then
              realpath -m -- "$p"
            else
              realpath -m -- "$(dirname -- "$p")"
            fi
            return
          fi

          # Fallback without realpath
          if [[ -d "$p" ]]; then
            (cd -- "$p" 2>/dev/null && pwd -P) || echo "$p"
          else
            local d; d="$(dirname -- "$p")"
            (cd -- "$d" 2>/dev/null && pwd -P) || echo "$d"
          fi
        }

        # Monkey-patch basename so that the upstream line:
        #   selected_name=$(basename "$selected" | tr . _)
        # yields the *folder* name even for ".", "..", files, etc.
        # We only special-case the common, single-argument form; everything else falls through.
        # IMPORTANT: We *only* treat the argument as a path if it looks like a path
        #            (/, ~, dot-paths, contains a slash) or actually exists on disk.
        #            This avoids mangling plain tokens like tmux session names.
        basename() {
          # If options or multiple args are used, don’t interfere.
          if [[ "$#" -ne 1 || "$1" == -* ]]; then
            command basename "$@"
            return
          fi

          local p="$1"

          # Heuristics: treat as "path-like" if any of:
          # - absolute path (/...), tilde (~...), dot paths (., .., */., */..)
          # - contains a slash anywhere
          # - exists on disk (file or directory) even without a slash (e.g., "README.md")
          if [[ "$p" == /* || "$p" == ~* || "$p" == "." || "$p" == ".." || "$p" == */. || "$p" == */.. || "$p" == *"/"* || -e "$p" ]]; then
            # For dot-paths or real paths, return the basename of the *directory*:
            # - If it's a file, use its parent dir
            # - If it's a dir/dot-path, use that dir
            local dir
            dir="$(_ts_abs_dir "$p")"
            command basename -- "$dir"
            return
          fi

          # Not path-like: let basename behave normally (e.g., "foo.bar" -> "foo.bar")
          command basename "$@"
        }
      '';

      tmux-sessionizer = pkgs.writeShellApplication {
        name = "tmux-sessionizer";

        runtimeInputs = with pkgs; [
          tmux
          fzf
          coreutils
        ];
        text = # bash
          ''
            TS_LOG=true
            TS_LOG_FILE=~/.local/share/tmux-sessionizer/tmux-sessionizer.logs
            TS_SEARCH_PATHS=(~/)
            TS_EXTRA_SEARCH_PATHS=()
            TS_SESSION_COMMANDS=("opencode \"\$(tmux display-message -p '#{pane_current_path}')\"")
            TS_MAX_DEPTH=9999

            ${tmux-sessionizer-shims}

            ${builtins.readFile "${tmux-sessionizer-source}/tmux-sessionizer"}
          '';
        excludeShellChecks = [
          "SC2236"
          "SC2155"
          "SC1090"
          "SC2004"
          "SC2086"
          "SC2128"
        ];
        bashOptions = [ ];
      };
    in
    {
      packages = [ tmux-sessionizer ];

      rum.programs.zsh.initConfig = lib.mkAfter ''
        alias ts=tmux-sessionizer
      '';

      xdg.config.files."tmux/tmux.conf".text = lib.mkAfter ''
        # tmux-sessionizer commands
        bind-key -r M-h run-shell "tmux-sessionizer -s 0"
      '';
    };
}
