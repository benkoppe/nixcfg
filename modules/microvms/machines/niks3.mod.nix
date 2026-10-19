{ inputs, self, ... }:
{
  flake.clan.machines.vm-niks3 =
    { config, pkgs, ... }:
    let
      vars = config.clan.core.vars.generators;

      port = 5751;

      vHosts = {
        cache = "cache.thekoppe.com";
        server = "niks3.thekoppe.com";
      };
    in
    {
      imports = with self.modules.nixos; [
        microvms_client
        public-endpoints_caddy
        public-endpoints_cloudflared

        inputs.niks3.nixosModules.niks3
      ];

      my.public-endpoints.niks3 = {
        vHost = vHosts.server;
        caddy.port = port;
        cloudflared = { };
      };

      microvm.mem = 1024;

      # niks3 stores reference/GC state in PostgreSQL.
      microvm.volumes = [
        {
          image = "niks3-postgresql.img";
          mountPoint = "/var/lib/postgresql";
          size = 4 * 1024;
        }
      ];

      services.niks3 = {
        enable = true;
        httpAddr = "127.0.0.1:${toString port}";

        cacheUrl = "https://${vHosts.cache}";
        serverUrl = "https://${vHosts.server}";

        apiTokenFile = vars.niks3-api-token.files.value.path;
        signKeyFiles = [
          vars.niks3-signing-key.files.secret-key.path
        ];

        s3 = {
          endpoint = "ec79e31bafd71cc19e54f7aa9636b50b.r2.cloudflarestorage.com";
          region = "auto";
          bucket = "nix-cache-thekoppe";
          useSSL = true;

          accessKeyFile = vars.niks3-r2.files.access-key.path;
          secretKeyFile = vars.niks3-r2.files.secret-key.path;
        };

        readProxy.enable = false;

        gc = {
          enable = true;
          olderThan = "2160h"; # 90 days
          schedule = "*-*-* 04:00:00";
        };

        # avoid uploading huge VM/disk artifacts.
        maxNarSize = "8G";
      };

      clan.core.vars.generators = {
        niks3-r2 = {
          prompts.access-key = {
            description = "niks3 R2 S3 access key";
            type = "hidden";
            persist = true;
          };
          prompts.secret-key = {
            description = "niks3 R2 S3 secret key";
            type = "hidden";
            persist = true;
          };
          files.access-key = {
            secret = true;
            owner = "niks3";
          };
          files.secret-key = {
            secret = true;
            owner = "niks3";
          };
          script = ''
            tr -d '\r\n' < "$prompts/access-key" > "$out/access-key"
            tr -d '\r\n' < "$prompts/secret-key" > "$out/secret-key"
          '';
        };

        niks3-api-token = {
          files.value = {
            secret = true;
            owner = "niks3";
          };
          script = "openssl rand -hex 32 | tr -d '\\n' > $out/value";
          runtimeInputs = [ pkgs.openssl ];
          share = true;
        };

        niks3-signing-key = {
          files.secret-key = {
            secret = true;
            owner = "niks3";
          };
          files.public-key.secret = false;

          script = ''
            nix --extra-experimental-features nix-command \
              key generate-secret \
              --key-name cache.thekoppe.com-1 \
              > "$out/secret-key"

            nix --extra-experimental-features nix-command \
              key convert-secret-to-public \
              < "$out/secret-key" \
              > "$out/public-key"
          '';
          runtimeInputs = [ pkgs.nix ];
        };
      };
    };
}
