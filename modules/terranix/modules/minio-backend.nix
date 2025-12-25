{
  flake.modules.terranix.minio-backend =
    { config, ... }:
    {
      terraform.backend.s3 = {
        bucket = "tfstate";
        endpoints.s3 = "https://minio.thekoppe.com";
        key = "${config.my.key}/terraform.tfstate";

        region = "us-east-1";
        skip_credentials_validation = true; # Skip AWS related checks and validations
        skip_requesting_account_id = true;
        skip_metadata_api_check = true;
        skip_region_validation = true;

        use_path_style = true;
      };
    };
}
