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

    onPush.default.outputs.effects = withSystem "x86_64-linux" (
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
  };

  hercules-ci.flake-update = {
    enable = true;

    effect.system = "x86_64-linux";

    nix.package =
      { pkgs }: self.inputs.determinate-nix.packages.${pkgs.stdenv.hostPlatform.system}.default;

    flakes."." = {
      commitSummary = "chore: update flake inputs";
    };

    pullRequestTitle = "chore: update `flake.lock`";
  };
}
