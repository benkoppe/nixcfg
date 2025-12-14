{
  imports = [
    ./caddy.nix
    ./nginx.nix
    ./hercules-ci-agent.nix
    ./acme-cloudflare.nix
    ./tailscale-server.nix
  ];
}
