{
  flake.modules.terranix.oracle =
    {
      lib,
      pkgs,
      config,
      ...
    }:
    (lib.mkMerge [
      {
        terraform.required_providers.oci = {
          source = "oracle/oci";
          version = "7.29.0";
        };
      }

      (lib.genAttrs
        [
          "region"
          "tenancy_ocid"
          "user_ocid"
          "fingerprint"
          "private_key"
        ]
        (key: {
          data.external.${key} = {
            program = [
              (lib.getExe (
                pkgs.writeShellApplication {
                  name = "get-clan-secret";
                  text = ''
                    jq -n --arg secret "$(clan secrets get oracle-${key})" '{"secret":$secret}'
                  '';
                }
              ))
            ];
          };
          provider.oci.${key} = config.data.external.${key} "result.secret";
        })
      )
    ]);

}
