{ self, lib, ... }:
{
  flake.clan.machines.vm-fastapi-dls =
    { pkgs, ... }:
    let
      fastapi-dls-override =
        self.inputs.fastapi-dls-nixos.packages.${pkgs.stdenv.targetPlatform.system}.default.overrideAttrs
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
    in
    {
      imports = with self.modules.nixos; [
        microvms_client

        self.inputs.fastapi-dls-nixos.nixosModules.default

        caddy
      ];

      my.caddy.virtualHosts = [
        {
          vHost = "dls.thekoppe.com";
          port = 8000;
          # address = "https://localhost";
        }
      ];

      services.fastapi-dls = {
        enable = true;
        listen.ip = "dls.thekoppe.com";
        listen.port = 443;
        extraOptions = {
          CORS_ORIGINS = "https://dls.thekoppe.com";
        };
      };

      systemd.services.fastapi-dls.serviceConfig.ExecStart =
        lib.mkForce "${lib.getBin fastapi-dls-override}/bin/fastapi-dls";
    };
}
