{
  withSystem,
  self,
  config,
  inputs,
  ...
}:
let
  inherit (config) mySnippets;
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
          ...
        }:
        let
          runHost =
            host:
            hci-effects.runNixOS (
              let
                inherit (mySnippets.hosts.${host}) ipv4;
              in
              {
                name = host;
                configuration = self.nixosConfigurations.${host};
                ssh.destination = ipv4;
                system = "x86_64-linux";
                secretsMap.ssh = "colmena-ssh";
                userSetupScript = ''
                  writeSSHKey ssh
                  cat >>~/.ssh/known_hosts <<EOF
                  ${ipv4} ${builtins.readFile "${inputs.secrets}/publicKeys/pve/${host}.pub"}
                  EOF
                '';
              }
            );
        in
        builtins.listToAttrs (
          map
            (host: {
              name = "deploy-${host}";
              value = hci-effects.runIf (config.repo.branch == "main") (runHost host);
            })
            [
              "russ"
              # "nix-builder"
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
