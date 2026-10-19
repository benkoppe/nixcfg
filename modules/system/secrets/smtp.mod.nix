{
  flake.modules.nixos.smtp-koppe-development = {
    clan.core.vars.generators.smtp-koppe-development = {
      prompts.password = {
        description = "SMTP password for koppe.development@gmail.com";
        type = "hidden";
        persist = true;
      };
      share = true;
    };
  };
}
