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
}
