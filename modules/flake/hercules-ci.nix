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
      ...
    }:
    let
      runColmena = hci-effects.mkEffect {
        inputs = [
          self.inputs.colmena.packages.${pkgs.stdenv.hostPlatform.system}.colmena
          self.inputs.determinate-nix.packages.${pkgs.stdenv.hostPlatform.system}.default
        ];

        effectScript = "colmena apply --config ${self.outPath}/flake.nix --nix-option accept-flake-config true";
      };
    in
    {
      deploy = runColmena;
    }
  );
}
