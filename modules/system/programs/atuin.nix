{
  flake.modules.hjem.atuin =
    { pkgs, lib, ... }:
    let
      pkg = pkgs.atuin;
    in
    {
      packages = [
        pkg
      ];

      xdg.config.files."atuin/config.toml" = {
        generator = (pkgs.formats.toml { }).generate "atuin-config.toml";
        value = {
          keymap_mode = "vim-insert";
          style = "auto";
          sync_address = "https://atuin.thekoppe.com";
        };
      };

      rum.programs.zsh.initConfig = lib.mkAfter ''
        if [[ $options[zle] = on ]]; then
          eval "$(${lib.getExe pkg} init zsh --disable-up-arrow)"
        fi
      '';
    };
}
