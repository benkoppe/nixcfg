{
  lib,
  config,
  inputs,
  ...
}:
{
  options.myNixOS.services.acme-cloudflare = {
    enable = lib.mkEnableOption "ACME Cloudflare DNS provider for certificate issuance";
  };

  config = lib.mkIf config.myNixOS.services.acme-cloudflare.enable {
    security.acme = {
      acceptTerms = true;
      defaults = {
        webroot = null;
        email = "koppe.development@gmail.com";
        dnsProvider = "cloudflare";
        dnsPropagationCheck = false;
        environmentFile = config.age.secrets.cloudflare-api.path;
      };
    };

    age.secrets.cloudflare-api.file = "${inputs.secrets}/services/caddy/cloudflare-api.age";
  };
}
