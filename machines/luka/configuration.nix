{ self, ... }:
{
  imports = with self.nixosModules; [
    nix
  ];
}
