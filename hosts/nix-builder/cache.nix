{
  config,
  pkgs,
  self,
  ...
}:
let
  nixServePort = 5000;
in
{
  services.nix-serve = {
    enable = true;

    package = pkgs.nix-serve-ng;
    secretKeyFile = config.age.secrets.nix-serve-key.path;

    bindAddress = "127.0.0.1";
    port = nixServePort;
  };

  age.secrets.nix-serve-key = {
    file = "${self.inputs.secrets}/services/nix-serve/key.age";
    owner = "root"; # `nix-serve` runs as root.
  };

  myNixOS = {
    services.caddy = {
      enable = true;

      virtualHosts =
        let
          rootIndexHtml = ''
              <html lang="en">
              <head>
                <title>cache.thekoppe.com is up</title>
                <link rel="stylesheet" href="https://nixos.org/bootstrap/css/bootstrap.min.css">
                <link rel="stylesheet" href="https://nixos.org/bootstrap/css/bootstrap-responsive.min.css">
                <style>
                  body { padding-top: 0; margin-top: 4em; margin-bottom: 4em; }
                  body > div { max-width: 800px; }
                  p { text-align: center; }
                  .cache { font-style: italic; }
                </style>
              </head>
              <body>
                <div class="container jumbotron">
                  <div class="jumbotron">
                    <p class="lead">
                      <img src="https://brand.nixos.org/logos/nixos-logo-default-gradient-black-regular-horizontal-minimal.svg"
                            width="400px">
                    </p>
                    <p class="lead">
                      <code>https://cache.thekoppe.com/</code> is a private source for prebuilt binaries.<br>
                      It is built on <a href="https://hercules-ci.com/github/benkoppe">Hercules CI</a>.
                    </p>
                  </div>
                  <hr>
                </div>
              </body>
            </html>
          '';
        in
        [
          {
            subdomain = "cache";
            port = nixServePort;
            extraConfig = [
              ''
                @root path /
                header @root Content-Type "text/html"
                respond @root <<EOF
                  ${rootIndexHtml}
                EOF
              ''
            ];
          }
        ];
    };
  };
}
