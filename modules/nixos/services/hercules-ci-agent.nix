{
  lib,
  config,
  self,
  ...
}:
{
  options.myNixOS.services.hercules-ci-agent = {
    enable = lib.mkEnableOption "Hercules CI Runner Agent";

    concurrentTasks = lib.mkOption {
      type = lib.types.int;
      default = 4;
      description = "Number of concurrent tasks the Hercules CI Agent can run.";
    };
  };

  config =
    let
      cfg = config.myNixOS.services.hercules-ci-agent;
    in
    lib.mkIf cfg.enable {
      services.hercules-ci-agent = {
        enable = true;

        settings = {
          clusterJoinTokenPath = config.age.secrets.hercules-token.path;
          binaryCachesPath = config.age.secrets.hercules-caches.path;
          secretsJsonPath = config.age.secrets.hercules-secrets.path;

          inherit (cfg) concurrentTasks;

          nixSettings = lib.removeAttrs (import (self + "/flake.nix")).nixConfig [
            "extra-substituters"
            "extra-trusted-private-keys"
          ];
        };
      };

      age.secrets =
        let
          common = secretFile: {
            file = secretFile;
            owner = "hercules-ci-agent";
          };
        in
        {
          hercules-token = common "${self.inputs.secrets}/services/hercules-ci/cluster-join-token.age";
          hercules-caches = common "${self.inputs.secrets}/services/hercules-ci/caches.age";
          hercules-secrets = common "${self.inputs.secrets}/services/hercules-ci/secrets.age";
        };
    };
}
