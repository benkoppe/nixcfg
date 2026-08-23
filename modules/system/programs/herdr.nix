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

      plugins = [
        selfPkgs.herdr-autoname
        selfPkgs.herdr-pluck
      ];

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

      xdg.config.files."herdr/config.toml" = {
        # type = "copy";
        # permissions = "0644";

        generator = (pkgs.formats.toml { }).generate "herdr-config.toml";

        value = {
          onboarding = false;

          keys = {
            prefix = "ctrl+space";

            focus_pane_left = "prefix+h";
            focus_pane_down = "prefix+j";
            focus_pane_up = "prefix+k";
            focus_pane_right = "prefix+l";

            split_vertical = "prefix+|";
            split_horizontal = "prefix+-";

            detach = "prefix+d";

            switch_tab = "prefix+1..9";
            switch_workspace = "prefix+shift+1..9";
            focus_agent = "prefix+alt+1..9";

            new_workspace = "prefix+shift+c";

            new_tab = [
              "prefix+c"
              "prefix+ctrl+c"
            ];
            next_tab = [
              "prefix+n"
              "prefix+ctrl+n"
            ];
            previous_tab = [
              "prefix+p"
              "prefix+ctrl+p"
            ];

            next_workspace = "prefix+shift+n";
            previous_workspace = "prefix+shift+p";

            next_agent = "prefix+alt+n";
            previous_agent = "prefix+alt+p";

            navigate_workspace_up = [
              "up"
              "p"
            ];
            navigate_workspace_down = [
              "down"
              "n"
            ];

            command = [
              {
                key = "prefix+alt+g";
                type = "popup";
                command = "lazygit";
                description = "open lazygit";
                width = "90%";
                height = "90%";
              }
              {
                key = "prefix+t";
                type = "popup";
                command = "exec \"\${SHELL:-sh}\"";
                description = "scratch terminal";
                width = "80%";
                height = "70%";
              }
              {
                key = "prefix+f";
                type = "plugin_action";
                command = "rmarganti.herdr-pluck.pluck";
                description = "pluck visible token";
              }
              {
                key = "prefix+shift+e";
                type = "pane";
                command = ''
                  tmp="$(mktemp "''${TMPDIR:-/tmp}/herdr-visible.XXXXXX")" || exit 1
                  trap 'rm -f "$tmp"' EXIT

                  "''${HERDR_BIN_PATH:-herdr}" pane read \
                    "$HERDR_ACTIVE_PANE_ID" \
                    --source visible \
                    --format text \
                    > "$tmp" || exit 1

                  "''${EDITOR:-nvim}" "$tmp"
                '';
                description = "edit visible pane contents";
              }
            ];
          };

          ui = {
            prompt_new_tab_name = false;
            agent_panel_sort = "spaces";

            sidebar = {
              agents.rows = [
                [
                  "state_icon"
                  "$autoname_index"
                  "workspace"
                  "agent"
                ]
                [ "tab" ]
              ];

              spaces.rows = [
                [
                  "state_icon"
                  "$autoname_index"
                  "workspace"
                ]
                [
                  "branch"
                  "git_status"
                ]
              ];
            };

            toast.delivery = "system";
          };

          theme.name = "tokyo-night";
        };
      };

      xdg.config.files."herdr/plugins/config/rmarganti.herdr-pluck/config.toml" = {
        generator = (pkgs.formats.toml { }).generate "herdr-pluck-config.toml";

        value = {
          # Works locally and through remote Herdr attachments.
          clipboard = "osc52";

          patterns = [
            {
              name = "nix-hash";
              regex = "(sha256-[0-9a-zA-Z=/+]{44}|[0-9a-f]{7,40}|[0-9a-z]{52})";
              priority = 25;
            }
          ];
        };

        clobber = true;
      };
    };
}
