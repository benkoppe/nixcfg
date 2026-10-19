{
  flake.modules.hjem.nushell =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      carapaceInit = pkgs.runCommand "carapace-init.nu" { } ''
        ${lib.getExe pkgs.carapace} _carapace nushell > "$out"
      '';
    in
    {
      packages = [
        pkgs.carapace
      ];

      rum.programs.nushell = {
        enable = true;

        settings = {
          show_banner = false;

          history = {
            file_format = "sqlite";
            max_size = 1000000;
          };

          edit_mode = "vi";

          cursor_shape = {
            emacs = "line";
            vi_insert = "line";
            vi_normal = "block";
          };

          completions.algorithm = "substring";
          highlight_resolved_externals = true;

          use_kitty_protocol = true;
          shell_integration.osc9_9 = true;

          table = {
            mode = "single";
            header_on_separator = true;
            footer_inheritance = true;
          };
        };

        aliases = (lib.mapAttrs (_: value: lib.mkDefault value) config.shellAliases) // {
          la = "ls --all";
          ll = "ls --long";
          lla = "ls --long --all";
        };

        extraConfig = ''
          source ${carapaceInit}

          def --env mc [path: path] {
            mkdir $path
            cd $path
          }

          $env.config.keybindings ++= [
            {
              name: accept_suggestion
              modifier: control
              keycode: char_y
              mode: [emacs vi_insert vi_normal]
              event: { send: HistoryHintComplete }
            }
            {
              name: accept_suggestion_word
              modifier: alt
              keycode: char_f
              mode: [emacs vi_insert vi_normal]
              event: { send: HistoryHintWordComplete }
            }
          ]
        '';
      };

      rum.programs.starship = {
        enable = true;

        integrations = {
          nushell.enable = true;
          zsh.enable = false;
          fish.enable = false;
        };

        settings = {
          add_newline = true;

          # Explicit module list keeps language/version modules out.
          format = lib.concatStrings [
            "[┏━](bold yellow) "
            "$hostname"
            "$directory"
            "$git_branch"
            "$git_status"
            "$nix_shell"
            "$status"
            "$cmd_duration"
            "$line_break"
            "$character"
          ];

          hostname = {
            ssh_only = true;
            format = "[@$hostname](bold green) ";
          };

          directory = {
            style = "bold cyan";
            truncation_length = 3;
            truncate_to_repo = true;
            format = "[$path]($style)[$read_only]($read_only_style) ";
          };

          git_branch = {
            symbol = "";
            style = "bold purple";
            format = "on [$branch]($style) ";
          };

          git_status = {
            style = "bold yellow";
            format = "([$all_status$ahead_behind]($style) )";
          };

          nix_shell = {
            symbol = "";
            style = "bold blue";
            format = "[nix:$state]($style) ";
          };

          status = {
            disabled = false;
            symbol = "";
            style = "bold red";
            format = "[exit:$status]($style) ";
          };

          cmd_duration = {
            min_time = 2000;
            style = "bold yellow";
            format = "took [$duration]($style) ";
          };

          character = {
            success_symbol = "[┃](bold yellow)";
            error_symbol = "[┃](bold red)";
            vimcmd_symbol = "[┃](bold green)";
          };
        };
      };
    };
}
