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
        pkgs.nushell
        pkgs.carapace
      ];

      xdg.config.files."nushell/settings.nu" = {
        generator = settings: ''
          $env.config = $env.config | merge deep (
            r###'${builtins.toJSON settings}'### | from json
          )
        '';

        value = {
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
      };

      xdg.config.files."nushell/aliases.nu".text = ''
        alias lg = lazygit

        alias la = ls --all
        alias ll = ls --long
        alias lla = ls --long --all

        def --env mc [path: path] {
          mkdir $path
          cd $path
        }
      '';

      xdg.config.files."nushell/config.nu".text = ''
        source ${config.xdg.config.files."nushell/settings.nu".source}
        source ${config.xdg.config.files."nushell/aliases.nu".source}

        source ${carapaceInit}
      '';
    };
}
