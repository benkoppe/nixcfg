{ lib, ... }:
{
  flake.modules.homeManager."ben_ghostty" =
    { pkgs, ... }:
    let
      inherit (pkgs.stdenv) isDarwin;
    in
    {
      programs.ghostty = {
        enable = true;

        package = lib.mkIf isDarwin pkgs.ghostty-bin;

        # installBatSyntax = !isDarwin;

        settings = {
          window-colorspace = "display-p3";
          theme = "0x96f";

          font-family = "MesloLG Nerd Font Mono";

          # 100 MiB
          scrollback-limit = 100 * 1024 * 1024;

          mouse-hide-while-typing = true;

          confirm-close-surface = false;
          quit-after-last-window-closed = true;
          mouse-shift-capture = false;

          window-decoration = isDarwin;
          macos-titlebar-style = "tabs";
        };
      };
    };
}
