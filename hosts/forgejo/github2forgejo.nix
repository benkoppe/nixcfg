{ inputs, config, ... }:
{
  imports = [ inputs.github2forgejo.nixosModules.default ];

  nixpkgs.overlays = [ inputs.github2forgejo.overlays.default ];

  services.github2forgejo = {
    enable = true;

    environmentFile = config.age.secrets.github2forgejo-env.path;

    # The default runs every day at midnight. But you can override it like so:
  };

  age.secrets.github2forgejo-env.file = "${inputs.secrets}/services/forgejo/github2forgejo-environment.age";
}
