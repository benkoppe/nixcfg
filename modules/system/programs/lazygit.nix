{
  flake.modules.hjem.lazygit =
    { pkgs, lib, ... }:
    {
      packages = [
        pkgs.lazygit
      ];

      xdg.config.files."lazygit/config.yml" = {
        generator = lib.generators.toYAML { };
        value = {
          promptToReturnFromSubprocess = false;

          git = {
            overrideGpg = true;
            pagers = [
              {
                externalDiffCommand = "${pkgs.difftastic}/bin/difft --color=always --display=inline --syntax-highlight=off";
              }
            ];
          };
        };
      };
    };
}
