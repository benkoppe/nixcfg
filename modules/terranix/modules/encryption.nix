{
  flake.modules.terranix.encryption =
    { lib, ... }:
    {
      variable.passphrase = {
        sensitive = true;
      };

      terraform.encryption = {
        key_provider.pbkdf2.encryption_password = {
          passphrase = lib.tfRef "var.passphrase";
        };
        method.aes_gcm.encryption_method = {
          keys = lib.tfRef "key_provider.pbkdf2.encryption_password";
        };
        state = {
          enforced = true;
          method = lib.tfRef "method.aes_gcm.encryption_method";
        };
        plan = {
          enforced = true;
          method = lib.tfRef "method.aes_gcm.encryption_method";
        };
      };
    };
}
