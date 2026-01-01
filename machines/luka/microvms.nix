{ self, ... }:
{
  imports = [ self.modules.nixos.microvms_host ];

  microvm.vms = {
    adguard = {
      pkgs = null;

      config = {
        imports = with self.modules.nixos; [
          basics
          microvms_client
        ];

        my.microvm.index = 1;

        microvm.shares = [
          {
            source = "/nix/store";
            mountPoint = "/nix/.ro-store";
            tag = "ro-store";
            proto = "virtiofs";
          }
        ];
      };
    };
  };
}
