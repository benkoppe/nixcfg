{
  withSystem,
  self,
  ...
}:
{
  herculesCI = _: {
    ciSystems = [
      "aarch64-linux"
      "x86_64-linux"
    ];
  };

  flake.effects = withSystem "x86_64-linux" (
    {
      hci-effects,
      pkgs,
      lib,
      ...
    }:
    let
      runColmena = hci-effects.mkEffect {
        inputs = [
          self.inputs.colmena.packages.${pkgs.stdenv.hostPlatform.system}.colmena
        ];
        src = lib.cleanSource ../../.;

        effectScript = "colmena apply --config $src";
      };
    in
    {
      deploy = runColmena;
    }
  );
}
