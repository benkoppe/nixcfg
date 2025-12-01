{
  lib,
  config,
  self,
  ...
}:
{
  options.myNixOS.services.acme-cloudflare = {
    enable = lib.mkEnableOption "ACME Cloudflare DNS provider for certificate issuance";
  };

  config = lib.mkIf config.myNixOS.services.acme-cloudflare {
    security.acme = {
      acceptTerms = true;
      defaults = {
        webroot = null;
        email = "koppe.development@gmail.com";
        dnsProvider = "cloudflare";
        dnsResolver = "1.1.1.1:53";
        dnsPropagationCheck = true;
        environmentFile = config.age.secrets.cloudflare-api.path;
      };
    };

    age.secrets.caddy-cloudflare.file = "${self.inputs.secrets}/services/caddy/cloudflare-api.age";
  };
}
