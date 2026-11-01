{ inputs, self, ... }:
{
  flake.modules.hjem.pi =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      inherit (pkgs.stdenv.hostPlatform) system;

      mcpJson = (pkgs.formats.json { }).generate "pi-mcp.json" {
        mcpServers = lib.mapAttrs (
          _: s:
          {
            inherit (s) enabled;
          }
          // (
            if s.url != null then
              { inherit (s) url; } // lib.optionalAttrs (s.headers != { }) { inherit (s) headers; }
            else
              { inherit (s) command args; } // lib.optionalAttrs (s.env != { }) { inherit (s) env; }
          )
        ) config.agents.mcp.servers;
      };

      agentDir = ./agent;

      agentFiles = lib.filesystem.listFilesRecursive agentDir;

      mkAgentFile =
        path:
        let
          relPath = lib.removePrefix "${toString agentDir}/" (toString path);
        in
        {
          name = ".pi/agent/${relPath}";
          value.source = path;
        };

      piAgentDeps = pkgs.callPackage ./_package.nix { };

      webToolsSource = "${inputs.dmmulroy-dotfiles}/home/.pi/agent/extensions/web-tools";

      webTools = pkgs.runCommand "pi-web-tools" { } ''
        mkdir -p "$out"
        cp -R ${webToolsSource}/. "$out/"
        ln -s ${piAgentDeps}/node_modules "$out/node_modules"
      '';

      # load extension from external inputs
      mkExternalExtension = input: extensionName: {
        name = ".pi/agent/extensions/${extensionName}";
        value.source = "${input}/${extensionName}";
      };

      externalExtensions = [
        {
          name = ".pi/agent/extensions/web-tools";
          value.source = webTools;
        }
      ]
      ++ (map (mkExternalExtension inputs.pi-agent-extensions) [
        "direnv"
        "notify"
        "questionnaire"
        "slow-mode"
        "stash"
        "statusline"
      ]);
    in
    {
      imports = with self.modules.hjem; [ ai-setup ];

      packages = [ inputs.llm-agents.packages.${system}.pi ];

      files =
        (builtins.listToAttrs (map mkAgentFile agentFiles))
        // (builtins.listToAttrs externalExtensions)
        // {
          ".pi/agent/mcp.json".source = mcpJson;
        };
    };
}
