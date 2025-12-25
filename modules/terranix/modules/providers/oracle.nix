{
  flake.modules.terranix.oracle =
    { lib, config, ... }:
    {
      terraform.required_providers.oci = {
        source = "oracle/oci";
        version = "7.29.0";
      };

      provider.oci = lib.genAttrs [ "region" "tenancy_ocid" "user_ocid" "fingerprint" "private_key" ] (
        _key: lib.tfRef "var.${config.my.key}"
      );

      variable =
        let
          var = description: {
            type = "string";
            sensitive = true;
            inherit description;
          };
        in
        {
          region = var "OCI region";
          tenancy_ocid = var "OCI tenancy OCID";
          user_ocid = var "OCI user OCID";
          fingerprint = var "OCI key pair fingerprint";
          private_key = var "OCI key pair private key";

          namespace = var "OCI Object Storage namespace";
          compartment_ocid = var "OCI compartment OCID";
        };
    };
}
