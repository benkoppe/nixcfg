{ inputs, self, ... }:
{
  flake.modules.hjem.herdr =
    {
      lib,
      pkgs,
      ...
    }:
    let
      inherit (pkgs.stdenv.hostPlatform) system;
      selfPkgs = self.packages.${system};

      plugins = [ selfPkgs.herdr-automatic-rename ];

      registryScript = pkgs.writeText "herdr-plugin-registry.nu" ''
        def main [...roots: string] {
          let plugins = (
            $roots
            | each {|root|
              let manifest_path = ($root | path join "herdr-plugin.toml")
              let manifest = (open $manifest_path)

              {
                plugin_id: $manifest.id
                name: $manifest.name
                version: $manifest.version
                min_herdr_version: ($manifest.min_herdr_version? | default "")
                manifest_path: $manifest_path
                plugin_root: $root
                enabled: true
                source: {
                  kind: "local"
                }
              }
            }
            | sort-by plugin_id
          )

          print ($plugins | to json --indent 2)
        }
      '';

      registry =
        pkgs.runCommand "herdr-plugins.json"
          {
            nativeBuildInputs = [ pkgs.nushell ];
          }
          ''
            nu ${registryScript} \
              ${lib.escapeShellArgs (map toString plugins)} \
              > "$out"
          '';
    in
    {
      packages = [
        inputs.llm-agents.packages.${system}.herdr
      ];

      xdg.config.files."herdr/plugins.json" = {
        source = registry;
        clobber = true;
      };
    };
}
