{
  flake.modules.terranix.options =
    { lib, ... }:
    {
      options.my.key = lib.mkOption {
        type = lib.types.str;
        description = ''
          Terraform key for the current configuration.
          Used for the S3 backend.
        '';
      };
    };
}
