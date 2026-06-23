{ inputs, ... }:
{
  flake.modules.hjem.pi =
    {
      lib,
      pkgs,
      ...
    }:
    let
      inherit (pkgs.stdenv.hostPlatform) system;

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
    in
    {
      packages = [
        (pkgs.writeShellScriptBin "pi" ''
          # Extensions are symlinked from dotfiles, so node walk-up misses
          # their npm deps. NODE_PATH points jiti at the prebuilt node_modules.
          export NODE_PATH="${piAgentDeps}/node_modules''${NODE_PATH:+:$NODE_PATH}"
          exec ${inputs.llm-agents.packages.${system}.pi}/bin/pi "$@"
        '')
      ];

      files = (builtins.listToAttrs (map mkAgentFile agentFiles)) // {
        ".pi/agent/extensions/web-tools" = {
          source = "${inputs.dmmulroy-dotfiles}/home/.pi/agent/extensions/web-tools";
        };
      };
    };
}
