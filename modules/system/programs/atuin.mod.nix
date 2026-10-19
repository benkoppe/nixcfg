{
  flake.modules.hjem.atuin =
    {
      config,
      pkgs,
      lib,
      ...
    }:
    let
      pkg = pkgs.atuin;
    in
    {
      options.atuin.sync.enable =
        lib.mkEnableOption "syncing atuin history to the self-hosted server"
        // {
          default = true;
        };

      config = {
        packages = [
          pkg
        ];

        xdg.config.files."atuin/config.toml" = {
          generator = (pkgs.formats.toml { }).generate "atuin-config.toml";
          value = {
            keymap_mode = "vim-insert";
            style = "auto";
            auto_sync = config.atuin.sync.enable;
            update_check = false;
          }
          // lib.optionalAttrs config.atuin.sync.enable {
            sync_address = "https://atuin.thekoppe.com";
          };
        };

        rum.programs.zsh.initConfig = lib.mkAfter ''
          if [[ $options[zle] = on ]]; then
            eval "$(${lib.getExe pkg} init zsh --disable-up-arrow)"
          fi
        '';
      };
    };
}
