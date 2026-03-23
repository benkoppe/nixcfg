{
  herculesCI = {
    ciSystems = [
      "aarch64-linux"
      "x86_64-linux"
    ];
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
