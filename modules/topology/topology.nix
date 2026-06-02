{ inputs, self, ... }:
{
  flake.modules.nixos.topology = {
    imports = [
      inputs.nix-topology.nixosModules.default
      self.modules.nixos."topology/extractors"
    ];
  };

  perSystem =
    {
      lib,
      pkgs,
      system,
      ...
    }:
    {
      topology.nixosConfigurations = lib.filterAttrs (
        name: cfg: cfg.config ? topology && !(lib.hasPrefix "vm-" name) && name != "butler"
      ) self.clan.nixosConfigurations;

      packages.topology-images =
        let
          topologyOutput = self.topology.${system}.config.output;
        in
        pkgs.runCommand "topology-images"
          {
            nativeBuildInputs = [
              pkgs.inkscape
              pkgs.python3
            ];

            FONTCONFIG_FILE = pkgs.makeFontsConf {
              fontDirectories = [ pkgs.jetbrains-mono ];
            };
          }
          ''
            mkdir -p "$out"

            cp -r ${topologyOutput}/. "$out/"
            chmod -R u+w "$out"

            OUT="$out" python3 <<'PY'
            import base64
            import os
            import pathlib
            import re
            import urllib.parse

            pattern = re.compile("href=\"data:image/svg\\+xml;utf8,([^\"]+)\"")

            for path in pathlib.Path(os.environ["OUT"]).glob("*.svg"):
                text = path.read_text()

                def repl(match):
                    svg = urllib.parse.unquote(match.group(1))
                    svg = svg.replace(" width=\"null\"", "")
                    svg = svg.replace(" height=\"null\"", "")
                    encoded = base64.b64encode(svg.encode()).decode()
                    return f"href=\"data:image/svg+xml;base64,{encoded}\""

                path.write_text(pattern.sub(repl, text))
            PY

            for svg in "$out"/*.svg; do
              name="$(basename "$svg" .svg)"
              inkscape "$svg" \
                --export-type=png \
                --export-area-page \
                --export-dpi=96 \
                --export-filename="$out/$name.png"
            done
          '';

      topology.modules = [
        # manual router/switch/network/cloud/oracle definitions here
        (
          { config, ... }:
          let
            inherit (config.lib.topology)
              mkConnection
              mkDevice
              mkInternet
              mkRouter
              mkSwitch
              ;
          in
          {
            networks = {
              home = {
                name = "Home LAN";
                cidrv4 = "192.168.1.0/24";
              };

              oracle-vcn = {
                name = "Oracle VCN";
                cidrv4 = "10.1.0.0/16";
              };

              cloudflare-tunnels.name = "Cloudflare tunnels";

              tailscale = {
                name = "Tailscale Tailnet";
                cidrv4 = "100.64.0.0/10";
                style = {
                  primaryColor = "#9b7cff";
                  secondaryColor = null;
                  pattern = "dotted";
                };
              };
            };

            nodes.internet = mkInternet {
              connections = [
                (mkConnection "router" "wan")
                (mkConnection "oracle" "wan")
                (mkConnection "cloudflare" "wan")
                (mkConnection "tailnet" "wan")
              ];
            };

            nodes.router = mkRouter "Home Router" {
              info = "ASUS RT-AC3100";
              image = ./assets/asus-rt-ac3100.png;

              interfaces.wan = { };
              interfaces.lan.network = "home";
              connections.lan = mkConnection "core-switch" "uplink";
            };

            nodes.core-switch = mkSwitch "Core Switch" {
              info = "Netgear GS608";
              image = ./assets/netgear-gs608.png;

              connections = {
                uplink = mkConnection "router" "lan";
                dray = mkConnection "dray" "eno1";
                luka = mkConnection "luka" "enp6s0";
                shai = mkConnection "shai" "eno1";
              };
            };

            nodes.cloudflare = mkDevice "Cloudflare" {
              info = "Public tunnel ingress";
              image = ./assets/cloudflare.png;

              interfaces = {
                wan = { };
                tunnel.network = "cloudflare-tunnels";
              };
            };

            nodes.tailnet = mkDevice "Tailscale Tailnet" {
              info = "Mesh VPN";
              image = ./assets/tailscale.png;

              interfaces = {
                wan = { };
                mesh.network = "tailscale";
              };
            };

            nodes.oracle = mkDevice "Oracle Cloud" {
              image = ./assets/oracle-cloud.png;

              interfaces = {
                wan = { };
                vcn = {
                  network = "oracle-vcn";
                  addresses = [ "10.1.0.0/16" ];
                };
              };

              connections.vcn = mkConnection "bird" "enp0s6";
            };

            nodes = {
              dray = {
                hardware.info = "Lenovo ThinkStation P520";
                interfaces.eno1.network = "home";
              };
              luka = {
                hardware.info = "2023 Custom Build";
                interfaces.enp6s0.network = "home";
              };
              shai = {
                hardware.info = "HP ProDesk 600 G5";
                interfaces.eno1.network = "home";
              };

              bird = {
                parent = "oracle";
                guestType = "OCI instance";

                interfaces.enp0s6.network = "oracle-vcn";
              };

              dray-cloudflared.interfaces.tunnel = {
                virtual = true;
                type = "tunnel";
                network = "cloudflare-tunnels";
                physicalConnections = [ (mkConnection "cloudflare" "tunnel") ];
              };

              luka-cloudflared.interfaces.tunnel = {
                virtual = true;
                type = "tunnel";
                network = "cloudflare-tunnels";
                physicalConnections = [ (mkConnection "cloudflare" "tunnel") ];
              };

              bird.interfaces.tailscale0.physicalConnections = [ (mkConnection "tailnet" "mesh") ];
              dray.interfaces.tailscale0.physicalConnections = [ (mkConnection "tailnet" "mesh") ];
              luka.interfaces.tailscale0.physicalConnections = [ (mkConnection "tailnet" "mesh") ];
              shai.interfaces.tailscale0.physicalConnections = [ (mkConnection "tailnet" "mesh") ];
            };
          }
        )
      ];
    };
}
