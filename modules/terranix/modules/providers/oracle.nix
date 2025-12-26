{
  flake.modules.terranix.oracle =
    {
      lib,
      pkgs,
      config,
      ...
    }:
    (lib.mkMerge (
      [
        {
          terraform.required_providers.oci = {
            source = "oracle/oci";
          };
        }
      ]
      ++ (
        let
          confKeys = [
            "region"
            "tenancy_ocid"
            "user_ocid"
            "fingerprint"
            "private_key"
          ];
          secretKeys = confKeys ++ [ "compartment_ocid" ];
        in
        (
          let
            mkSecretData = key: {
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
            };
          in
          map mkSecretData secretKeys
        )
        ++ (
          let
            mkOracleConf = key: {
              provider.oci.${key} = config.data.external.${key} "result.secret";
            };
          in
          map mkOracleConf confKeys
        )
      )
    ));
}
