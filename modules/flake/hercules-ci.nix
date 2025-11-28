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
    { hci-effects, pkgs, ... }:
    let
      flakePath = self.outPath;
      runColmena = hci-effects.mkEffect {
        inputs = [
          self.inputs.colmena.packages.${pkgs.stdenv.hostPlatform.system}.colmena
          flakePath
        ];

        effectScript = "colmena apply --config ${flakePath}";
      };
    in
    {
      deploy = runColmena;
    }
  );
}
