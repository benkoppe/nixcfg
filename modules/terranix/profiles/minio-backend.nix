{ config, lib, ... }:
{
  options.myTerranix.profiles.minio-backend.enable = lib.mkOption {
    type = lib.types.bool;
    default = true;
    description = "Enable minio s3 storage backend for .tfstate";
  };

  config = lib.mkIf config.myTerranix.profiles.minio-backend.enable {
    terraform.backend.s3 = {
      bucket = "tfstate";
      endpoints.s3 = "https://minio.thekoppe.com";
      key = "${config.mySnippets.hostName}/terraform.tfstate";

      region = "us-east-1";
      skip_credentials_validation = true; # Skip AWS related checks and validations
      skip_requesting_account_id = true;
      skip_metadata_api_check = true;
      skip_region_validation = true;

      use_path_style = true;
    };
  };
}
