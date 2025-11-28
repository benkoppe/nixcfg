{
  pkgs,
  withSystem,
  hci-effects,
  self,
  ...
}:
let
  runColmena = hci-effects.mkEffect {
    inputs = [
      self.inputs.colmena.packages.${pkgs.stdenv.hostPlatform.system}.colmena
    ];

    effectScript = "colmena apply";
  };
in
{
  herculesCI = _: {
    ciSystems = [
      "aarch64-linux"
      "x86_64-linux"
    ];
  };

  flake.effects =
    { branch, ... }:
    withSystem "x86_64-linux" (
      {
        config,
        hci-effects,
        pkgs,
        inputs',
        ...
      }:
      {
        deploy = runColmena;
      }
    );
}
