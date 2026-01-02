{
  flake.modules.nixos.cloudflare-api = {
    clan.core.vars.generators.cloudflare = {
      prompts.api-token = {
        description = "Cloudflare api token";
        type = "hidden";
        persist = true;
      };
      share = true;
    };
  };

  flake.modules.nixos.cloudflare-acme =
    { hostConfig, ... }:
    {
      microvm.shares = [
        {
          source = builtins.dirOf hostConfig.clan.core.vars.generators.cloudflare.files.api-token.path;
          mountPoint = "/var/run/secrets/cloudflare";
          tag = "authKey";
          proto = "virtiofs";
          readOnly = true;
        }
      ];

      security.acme = {
        acceptTerms = true;
        defaults = {
          webroot = null;
          email = "koppe.development@gmail.com";
          dnsProvider = "cloudflare";
          dnsResolver = "1.1.1.1:53";
          dnsPropagationCheck = true;
          credentialFiles.CLOUDFLARE_DNS_API_TOKEN_FILE = "/var/run/secrets/cloudflare/api-token";
        };
      };
    };
}
