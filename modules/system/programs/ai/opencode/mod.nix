{ self, inputs, ... }:
{
  flake.modules.hjem.opencode =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      inherit (pkgs.stdenv.hostPlatform) system;
      plannotatorSource = inputs.llm-agents.packages.${system}.plannotator.src;

      mcpServers = lib.mapAttrs (
        _: s:
        {
          disabled = !s.enabled;
        }
        // (
          if s.url != null then
            {
              type = "remote";
              inherit (s) url;
            }
            // lib.optionalAttrs (s.headers != { }) { inherit (s) headers; }
          else
            {
              type = "local";
              command = [ s.command ] ++ s.args;
            }
            // lib.optionalAttrs (s.env != { }) { environment = s.env; }
        )
      ) config.agents.mcp.servers;
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
          ];

          plugins = [
            {
              package = "@plannotator/opencode@latest";
              options.workflow = "manual";
            }
          ];

          mcp.servers = mcpServers;
        };
      };
    };
}
