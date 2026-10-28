{ inputs, ... }:
{
  flake.modules.nixos.rex =
    { config, ... }:
    {
      imports = [ inputs.rex.nixosModules.default ];

      clan.core.vars.generators.rex-tailscale-auth-key = {
        prompts.key.persist = true;
        share = true;
      };

      services.tailscale = {
        enable = true;
        authKeyFile = config.clan.core.vars.generators.rex-tailscale-auth-key.files.key.path;
        extraSetFlags = [ "--accept-routes=false" ];
      };

      services.rex.loginServer =
        let
          me = "tailscale:benkoppe@github";
          # tagged devices, like ant, never match a user login
          adminDevices = "tailscale:tag:admin-personal-device";
        in
        {
          enable = true;

          accounts.ben.principals = [
            me
            adminDevices
          ];
          defaults = {
            ${me} = "ben";
            ${adminDevices} = "ben";
          };

          tailscaleServe.enable = true;
        };
    };
}
