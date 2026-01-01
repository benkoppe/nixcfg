{ self, ... }:
{
  imports = [ self.modules.nixos.microvms_host ];

  microvm.vms = {
    adguard = {
      pkgs = null;

      config = {
        imports = with self.modules.nixos; [
          microvms_client
        ];

        my.microvm.index = 1;
      };
    };
  };
}
