{
  flake.modules.hjem.lazygit =
    { pkgs, lib, ... }:
    {
      packages = [
        pkgs.lazygit
      ];

      shellAliases.lg = "lazygit";

      xdg.config.files."lazygit/config.yml" = {
        generator = lib.generators.toYAML { };
        value = {
          promptToReturnFromSubprocess = false;

          gui = {
            nerdFontsVersion = "3";

            spinner = {
              frames = [
                "|"
                "/"
                "-"
                "\\"
              ];
              rate = 100;
            };
          };

          git = {
            overrideGpg = true;
            diffRenderers = [
              {
                type = "extDiff";
                name = "difftastic";
                command = "${pkgs.difftastic}/bin/difft --color=always --display=inline --syntax-highlight=off --context={{diffContext}}";
              }
              {
                type = "stdinFilter";
                name = "delta";
                command = "${pkgs.delta}/bin/delta --paging=never --line-numbers --hyperlinks --hyperlinks-file-link-format=\"lazygit-edit://{path}:{line}\"";
              }
              {
                type = "rawGit";
                name = "git";
              }
            ];
          };
        };
      };
    };
}
