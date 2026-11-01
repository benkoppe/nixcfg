{ self, inputs, ... }:
{
  flake.modules.hjem.opencode =
    { lib, pkgs, ... }:
    let
      inherit (pkgs.stdenv.hostPlatform) system;
      plannotatorSource = inputs.llm-agents.packages.${system}.plannotator.src;
    in
    {
      imports = with self.modules.hjem; [ ai-setup ];

      packages =
        let
          llm-agents = inputs.llm-agents.packages.${system};
          # Rex picks the sidebar icon from argv0, and only knows "opencode".
          opencode2 = pkgs.runCommand "opencode2" { nativeBuildInputs = [ pkgs.makeWrapper ]; } ''
            makeWrapper ${llm-agents.opencode2}/bin/.opencode2-wrapped $out/bin/opencode2 \
              --argv0 opencode \
              --prefix PATH : ${lib.makeBinPath [ pkgs.ripgrep ]}
          '';
        in
        [
          opencode2
          llm-agents.plannotator
        ];

      xdg.config.files."opencode/skills".source = builtins.path {
        path = ./skills;
        name = "opencode-skills";
      };

      xdg.config.files."opencode/commands/plannotator-review.md".source =
        "${plannotatorSource}/apps/opencode-plugin/commands/plannotator-review.md";

      xdg.config.files."opencode/commands/plannotator-annotate.md".source =
        "${plannotatorSource}/apps/opencode-plugin/commands/plannotator-annotate.md";

      xdg.config.files."opencode/commands/plannotator-last.md".source =
        "${plannotatorSource}/apps/opencode-plugin/commands/plannotator-last.md";

      xdg.config.files."opencode/opencode.json" = {
        generator = lib.generators.toJSON { };
        value = {
          "$schema" = "https://opencode.ai/config.json";

          update = "disable";

          skills = [
            "${plannotatorSource}/apps/skills/core"
            "${inputs.pstack}/pstack/skills"
          ];

          plugins = [
            {
              package = "@plannotator/opencode@latest";
              options.workflow = "manual";
            }
          ];
        };
      };
    };
}
