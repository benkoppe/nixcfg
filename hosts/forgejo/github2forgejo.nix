{ self, config, ... }:
{
  imports = [ self.inputs.github2forgejo.nixosModules.default ];

  nixpkgs.overlays = [ self.inputs.github2forgejo.overlays.default ];

  services.github2forgejo = {
    enable = true;

    environmentFile = config.age.secrets.github2forgejo-env.path;

    # The default runs every day at midnight. But you can override it like so:
  };

  age.secrets.github2forgejo-env.file = "${self.inputs.secrets}/services/forgejo/github2forgejo-environment.age";
}
