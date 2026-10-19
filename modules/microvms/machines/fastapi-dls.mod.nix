{ self, lib, ... }:
{
  flake.clan.machines.vm-fastapi-dls =
    { pkgs, config, ... }:
    let
      fastapi-dls-override =
        (pkgs.callPackage "${self.inputs.fastapi-dls-nixos}/package.nix" { }).overrideAttrs
          (old: {
            preBuild = old.preBuild + ''
                    cat > fastapi_dls/run.py << 'EOF'
              import uvicorn
              import os

              def main():
                  uvicorn.run(
                      "fastapi_dls.main:app",
                      host="localhost",
                      port=8000,
                      proxy_headers=True,
                  )
              EOF
            '';
          });

      endpoint = config.my.public-endpoints.fastapi-dls;
    in
    {
      # TODO: remove soon
      nixpkgs.overlays = [
        (_: prev: {
          pythonPackagesExtensions = prev.pythonPackagesExtensions ++ [
            (_: python-prev: {
              inline-snapshot = python-prev.inline-snapshot.overridePythonAttrs (old: {
                # The documentation snapshots expect an older Black formatter.
                disabledTestPaths = (old.disabledTestPaths or [ ]) ++ [ "tests/test_docs.py" ];
              });
            })
          ];
        })
      ];

      imports = with self.modules.nixos; [
        microvms_client

        self.inputs.fastapi-dls-nixos.nixosModules.default

        public-endpoints_caddy
      ];

      my.public-endpoints.fastapi-dls = {
        vHost = "dls.thekoppe.com";
        caddy.port = 8000;
      };

      services.fastapi-dls = {
        enable = true;
        listen.ip = endpoint.vHost;
        listen.port = 443;
        extraOptions = {
          CORS_ORIGINS = "https://${endpoint.vHost}";
        };
      };

      systemd.services.fastapi-dls.serviceConfig.ExecStart =
        lib.mkForce "${lib.getBin fastapi-dls-override}/bin/fastapi-dls";
    };
}
