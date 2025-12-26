{
  # Merely enforces encryption, so no data is accidentally stored unencrypted.
  # Actual encryption must be set using the env var in my-terranix.nix due to terranix constraints.
  flake.modules.terranix.encryption = {
    variable.passphrase = {
      sensitive = true;
    };

    terraform.encryption = {
      state = {
        enforced = true;
      };
      plan = {
        enforced = true;
      };
    };
  };
}
