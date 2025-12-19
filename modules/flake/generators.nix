{ inputs, self, ... }:
{
  perSystem =
    {
      lib,
      system,
      ...
    }@ctx:
    {
      packages =
        lib.mkIf
          (lib.elem system [
            "x86_64-linux"
            "aarch64-linux"
          ])
          {
            lxc-bootstrap = inputs.nixos-generators.nixosGenerate {
              inherit system;
              format = "proxmox-lxc";
              specialArgs = {
                inherit self inputs;
                inherit (ctx) inputs' system;
              };
              modules = [
                self.nixosModules.default
                ../../hosts/lxc-bootstrap
                {
                  mySnippets.hostName = "lxc-bootstrap";
                }
              ];
            };

            vm-bootstrap = inputs.nixos-generators.nixosGenerate {
              inherit system;
              format = "qcow-efi";
              specialArgs = {
                inherit self inputs;
                inherit (ctx) inputs' system;
              };
              modules = [
                self.nixosModules.default
                ../../hosts/vm-bootstrap
                {
                  mySnippets.hostName = "vm-bootstrap";
                }
              ];
            };
          };

    };
}
