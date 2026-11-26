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
      imports = with self.modules.hjem; [
        ai-setup
        plannotator
      ];

      packages =
        let
          llm-agents = inputs.llm-agents.packages.${system};
          # Rex's sidebar icon and resume rule both expect "opencode".
          opencode2 = pkgs.runCommand "opencode2" { nativeBuildInputs = [ pkgs.makeWrapper ]; } ''
            makeWrapper ${llm-agents.opencode2}/bin/.opencode2-wrapped $out/bin/opencode2 \
              --argv0 opencode \
              --prefix PATH : ${lib.makeBinPath [ pkgs.ripgrep ]}
            ln -s opencode2 $out/bin/opencode
          '';
        in
        [
          opencode2
        ];

      xdg.config.files."opencode/opencode.json" = {
        generator = lib.generators.toJSON { };
        value = {
          "$schema" = "https://opencode.ai/config.json";

          update = "disable";

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
