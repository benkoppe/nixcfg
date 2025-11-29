{
  withSystem,
  self,
  lib,
  config,
  ...
}:
let
  topConfig = config;
in
{
  herculesCI =
    { config, ... }:
    {
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
          # deploy = hci-effects.runIf (config.repo.branch == "main") runColmena;
        }
        // (
          let
            runHost =
              host:
              hci-effects.runNixOS {
                name = host;
                configuration = self.nixosConfigurations.${host};
                ssh.destination = topConfig.mySnippets.hosts.${host}.ipv4;
                system = "x86_64-linux";
                secretsMap.ssh = "colmena-ssh";
                userSetupScript = "writeSSHKey ssh";
              };
          in
          builtins.listToAttrs (
            map
              (host: {
                name = "deploy-${host}";
                value = hci-effects.runIf (config.repo.branch == "main") (runHost host);
              })
              [
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
              ]
          )
        )
      );
    };

  hercules-ci.flake-update = {
    enable = true;

    effect.system = "x86_64-linux";

    nix.package = { inputs', ... }: inputs'.determinate-nix.packages.default;

    flakes."." = {
      commitSummary = "chore: update flake inputs";
    };

    pullRequestTitle = "chore: update `flake.lock`";

    when = {
      hour = [ 23 ];
    };
  };
}
