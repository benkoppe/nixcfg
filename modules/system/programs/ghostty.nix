{ lib, ... }:
{
  flake.modules.hjem.ghostty =
    { pkgs, ... }:
    let
      inherit (pkgs.stdenv) isDarwin;
    in
    {
      rum.programs.ghostty = {
        enable = true;

        package = lib.mkIf isDarwin pkgs.ghostty-bin;

        settings = lib.mkMerge [
          {
            window-colorspace = "display-p3";
            theme = "0x96f";

            font-family = "MesloLG Nerd Font Mono";

            # 100 MiB
            scrollback-limit = 100 * 1024 * 1024;

            mouse-hide-while-typing = true;

            confirm-close-surface = false;
            quit-after-last-window-closed = true;
            mouse-shift-capture = false;

            # zsh is good enough at handling the title
            shell-integration-features = "no-title";

            cursor-style = "bar";
            cursor-style-blink = true;
          }

          (lib.mkIf isDarwin {
            macos-titlebar-style = "tabs";
          })

          (lib.mkIf (!isDarwin) {
            window-decoration = false;
            window-padding-x = 12;
            window-padding-y = 12;
            background-opacity = 1.0;
            background-blur-radius = 32;

            app-notifications = "no-clipboard-copy";
            clipboard-read = "allow";

            keybind = [
              "ctrl+t=new_tab"
              "ctrl+plus=increase_font_size:1"
              "ctrl+minus=decrease_font_size:1"
              "ctrl+zero=reset_font_size"
            ];
          })
        ];
      };

      rum.programs.zsh.plugins.ghostty-integration.source =
        lib.mkIf isDarwin "${pkgs.ghostty-bin}/Applications/Ghostty.app/Contents/Resources/ghostty/shell-integration/zsh/ghostty-integration";
    };
}
