{ self, ... }:
{
  flake.modules.nixos.qmk =
    { pkgs, lib, ... }:
    {
      hardware.keyboard.qmk = {
        enable = true;
        keychronSupport = lib.mkDefault true;
      };

      environment.systemPackages = with pkgs; [ qmk ];
    };

  flake.modules.nixos.vial =
    { pkgs, ... }:
    {
      environment.systemPackages = with pkgs; [ vial ];

      services.udev.packages = with pkgs; [ vial ];
    };

  flake.modules.nixos.qmk-full = {
    imports = with self.modules.nixos; [
      qmk
      vial
    ];
  };
}
