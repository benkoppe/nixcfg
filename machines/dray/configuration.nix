{
  self,
  pkgs,
  ...
}:
{
  imports = with self.modules.nixos; [
    basics
    zfs-encrypt
  ];

  clan.core.vars.generators.zfs-encrypt-tank0 = {
    files.password = {
      secret = true;
      neededFor = "partitioning";
    };
    script = ''
      openssl rand -hex 48 > $out/password
    '';
    runtimeInputs = with pkgs; [
      openssl
    ];
  };

  # New machine!
}
