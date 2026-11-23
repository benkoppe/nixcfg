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
      imports = with self.modules.nixos; [
        microvms_client

        # Import with `self = null` so the module builds its package from this VM's pkgs
        # (respecting nixpkgs.config) instead of the input's unconfigured legacyPackages.
        (import "${self.inputs.fastapi-dls-nixos}/default.nix" { })

        public-endpoints_caddy
      ];

      # CVE-2026-120459 (python-jose accepts empty HMAC keys) doesn't affect fastapi-dls:
      # it only signs/verifies with RS256 using RSA keys (algorithms pinned in jwt.decode).
      # Pinned to the exact version so a future bump forces a re-check.
      nixpkgs.config.permittedInsecurePackages = [ "python3.12-python-jose-3.5.0" ];

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
