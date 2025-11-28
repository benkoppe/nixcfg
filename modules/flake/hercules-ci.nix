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
          pkgs.openssh
        ]
        ++ (map (host: self.nixosConfigurations.${host}.config.system.build.toplevel) [
          "russ"
          "nix-builder"
          "adguard"
          "lldap"
          "pocket-id"
          "vaultwarden"
          "immich"
          "forgejo"
          "forgejo-runner"
          "garage-dray"
          "komodo"
        ]);

        secretsMap.ssh = "colmena-ssh";

        userSetupScript = "writeSSHKey ssh";

        effectScript = "colmena apply --config ${self.outPath}/flake.nix --nix-option accept-flake-config true";
      };
    in
    {
      deploy = runColmena;
    }
  );
}
