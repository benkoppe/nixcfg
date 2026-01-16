{ self, ... }:
{
  imports = with self.modules.nixos; [
    basics
    tailgate
  ];
}
