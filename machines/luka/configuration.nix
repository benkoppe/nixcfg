{ self, ... }:
{
  imports = with self.nixosModules; [
    nix
  ];

  clan.core.vars.generators.luks-password = {
    prompts.password = {
      description = "LUKS password for machine luka";
      type = "hidden";
    };
    files.password = {
      secret = true;
      neededFor = "partitioning";
    };

    script = "cp $prompts/password $out/password";
  };
}
