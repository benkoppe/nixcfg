{
  flake.modules.hjem.vesktop =
    { pkgs, lib, ... }:
    let
      themes = {
        # "my-theme" = ''
        #   :root {
        #     --background-primary: #000;
        #   }
        # '';
      };
    in
    {
      packages = [
        (pkgs.vesktop.override {
          withSystemVencord = true;
        })
      ];

      xdg.config.files = {
        # vesktop settings
        "vesktop/settings.json" = {
          generator = lib.generators.toJSON { };
          value = { };
        };

        # vencord settings
        "vesktop/settings/settings.json" = {
          generator = lib.generators.toJSON { };
          value = { };
        };

        "vesktop/settings/quickCss.css".text = "";
      }
      // lib.mapAttrs' (
        name: value:
        lib.nameValuePair "vesktop/themes/${name}.css" {
          text = value;
        }
      ) themes;
    };
}
