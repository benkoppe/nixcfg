{
  inputs,
  self,
  ...
}:
{
  perSystem =
    {
      lib,
      system,
      pkgs,
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

            oci-bootstrap-image =
              let
                img = self.nixosConfigurations.oci-bootstrap.config.system.build.OCIImage;
              in
              pkgs.runCommand "nixos-oci-image.qcow2" { } ''
                # Use a glob to find the qcow2 file regardless of the date string in the name
                cp ${img}/*.qcow2 $out
              '';
          };

    };
}
