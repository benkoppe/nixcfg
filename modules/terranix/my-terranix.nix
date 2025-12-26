{
  self,
  lib,
  config,
  ...
}:
let
  inherit (lib) mkOption types;
in
{
  options.my.terranix = mkOption {
    type = types.attrsOf (
      types.submodule (
        { name, ... }:
        {
          options = {
            modules = mkOption {
              type = types.listOf types.anything;
              default = [ ];
              description = "List of terranix modules to include.";
            };
            key = mkOption {
              type = types.str;
              default = name;
              description = "Workdir key for this configuration";
            };
            providers = mkOption {
              type = types.listOf (types.enum [ "oracle" ]);
              default = [ ];
              description = "Terraform providers enabled for this config";
            };
          };
        }
      )
    );

    default = { };
    description = "My terranix submodules";
  };

  config.perSystem =
    { pkgs, inputs', ... }:
    let
      defaultModules = with self.modules.terranix; [
        encryption
      ];
      providerModules = {
        inherit (self.modules.terranix) oracle;
      };
      providerPlugins = {
        oracle = p: [ p.oracle_oci ];
      };
    in
    {
      terranix.terranixConfigurations = lib.mapAttrs (name: cfg: {
        modules = cfg.modules ++ defaultModules ++ map (p: providerModules.${p}) cfg.providers;

        workdir = "terraform-state/${cfg.key}";

        terraformWrapper = {
          package = pkgs.opentofu.withPlugins (
            p: [ p.hashicorp_external ] ++ lib.flatten (map (prov: providerPlugins.${prov} p) cfg.providers)
          );

          extraRuntimeInputs = [ inputs'.clan-core.packages.default ];
          prefixText = ''
            TF_VAR_passphrase=$(clan secrets get terraform-passphrase)
            export TF_VAR_passphrase

            TF_ENCRYPTION=$(cat <<'EOF'
            key_provider "pbkdf2" "encryption_password" {
              passphrase = var.passphrase
            }
            method "aes_gcm" "encryption_method" {
              keys = key_provider.pbkdf2.encryption_password
            }
            state {
              method = method.aes_gcm.encryption_method
            }
            plan {
              method = method.aes_gcm.encryption_method
            }
            EOF
            )

            # shellcheck disable=SC2090
            export TF_ENCRYPTION
          '';
        };
      }) config.my.terranix;
    };

}
