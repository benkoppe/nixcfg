{ inputs, ... }:
{
  flake.modules.nixos.github2forgejo =
    { config, ... }:
    {
      imports = [ inputs.github2forgejo.nixosModules.default ];

      nixpkgs.overlays = [ inputs.github2forgejo.overlays.default ];

      clan.core.vars.generators.github2forgejo-env = {
        prompts.env-file = {
          description = "Environment file for github2forgejo service";
          type = "multiline";
          persist = true;
        };
        share = true;
      };

      services.github2forgejo = {
        enable = true;

        environmentFile = config.clan.core.vars.generators.github2forgejo-env.files.env-file.path;

        # The default runs every day at midnight. But you can override it like so:
      };
    };
}
