{ self, lib, ... }:
{
  flake.modules.nixos.steam-microvm =
    { pkgs, config, ... }:
    {
      virtualisation.libvirtd.enable = true;
      boot.kernelModules = [ "kvm-amd" ];
      users.users.microvm.extraGroups = [
        "qemu-libvirtd"
        "libvirtd"
        "wheel"
        "audio"
      ];

      networking.useNetworkd = true;

      systemd.network.networks =
        let
          maxVMs = 64;
        in
        builtins.listToAttrs (
          map (index: {
            name = "30-vm${toString index}";
            value = {
              matchConfig.Name = "vm${toString index}";
              # Host's addresses
              address = [
                "10.0.0.0/32"
              ];
              # Setup routes to the VM
              routes = [
                { Destination = "10.0.0.${toString index}/32"; }
              ];
              networkConfig = {
                IPv4Forwarding = true;
                # IPv6Forwarding = true;
              };
            };
          }) (lib.genList (i: i + 1) maxVMs)
        );

      networking.nat = {
        enable = true;
        internalIPs = [ "10.0.0.0/24" ];
        externalInterface = "enp6s0";
      };

      clan.core.vars.generators.jokic-ssh = {
        files."ssh_host_ed25519_key" = {
          secret = true;
          owner = "root";
          group = "root";
          mode = "0600";
        };
        files."ssh_host_ed25519_key.pub" = {
          secret = false;
        };
        runtimeInputs = [ pkgs.openssh ];
        script = ''ssh-keygen -t ed25519 -N "" -f $out/ssh_host_ed25519_key'';
      };

      clan.core.vars.generators.gamer-password = {
        prompts.password-input = {
          description = "Password for the gamer user";
          type = "hidden";
          persist = false;
        };
        files.password-hash.secret = false;
        script = ''
          cat $prompts/password-input | mkpasswd -m sha-512 > $out/password-hash
        '';
        runtimeInputs = [ pkgs.mkpasswd ];
      };

      services.udev.extraRules = ''
        # Razer Viper Mini
        SUBSYSTEM=="usb", ATTR{idVendor}=="1532", ATTR{idProduct}=="008a", GROUP="kvm"

        # Keychron V6
        SUBSYSTEM=="usb", ATTR{idVendor}=="3434", ATTR{idProduct}=="0361", GROUP="kvm"
      '';

      microvm.vms = {
        jokic = {
          pkgs = import self.inputs.nixpkgs {
            system = "x86_64-linux";
            config.allowUnfree = true;
          };

          config =
            let
              index = 1;
              mac = "00:00:00:00:00:01";
            in
            {
              imports = with self.modules.nixos; [
                nix
              ];
              services.openssh.enable = true;
              services.openssh.hostKeys = [
                {
                  path = "/run/secrets/ssh/ssh_host_ed25519_key";
                  type = "ed25519";
                }
              ];

              users.mutableUsers = false;
              users.users.gamer = {
                hashedPasswordFile = config.clan.core.vars.generators.gamer-password.files."password-hash".path;
                group = "gamer";
                isNormalUser = true;
                extraGroups = [
                  "video"
                  "render"
                  "seat"
                ];
              };
              users.groups.gamer = { };

              time.timeZone = lib.mkDefault "America/Los_Angeles";

              hardware.graphics.enable = true;
              services.xserver.videoDrivers = [ "nvidia" ];
              hardware.nvidia = {
                open = true;
                modesetting.enable = true;
              };

              programs.steam = {
                enable = true;
                gamescopeSession.enable = true;
              };
              programs.gamescope = {
                enable = true;
                capSysNice = true;
              };
              services.seatd.enable = true;

              environment = {
                systemPackages = [ pkgs.mangohud ];
                loginShellInit = ''
                  [[ "$(tty)" = "/dev/tty1" ]] && /etc/gs.sh
                '';
                etc."gs.sh" = {
                  mode = "0755";
                  text = ''
                    #!/usr/bin/env bash
                    set -xeuo pipefail

                    gamescopeArgs=(
                      --adaptive-sync
                      --hdr-enabled
                      --mangoapp
                      --rt
                      --steam
                    )
                    steamArgs=(
                      -pipewire-dmabuf
                      -tenfoot
                    )
                    mangoConfig=(
                      cpu_temp
                      gpu_temp
                      ram
                      vram
                    )
                    mangoVars=(
                      MANGOHUD=1
                      MANGOHUD_CONFIG="$(IFS=,; echo "''${mangoConfig[*]}")"
                    )
                    export "''${mangoVars[@]}"
                    exec gamescope "''${gamescopeArgs[@]}" -- steam "''${steamArgs[@]}"
                  '';
                };
              };

              microvm.vcpu = 8;
              microvm.mem = 16384;

              nix.optimise.automatic = lib.mkForce false;
              # microvm.optimize.enable = false;
              microvm.balloon = false;
              microvm.storeOnDisk = true;
              # microvm.writableStoreOverlay = "/nix/.rw-store";
              # fileSystems."/nix/.rw-store" = {
              #   fsType = "tmpfs";
              #   options = [
              #     "mode=0755"
              #     "size=4G"
              #   ];
              # };

              microvm.shares = [
                {
                  source =
                    builtins.dirOf
                      config.clan.core.vars.generators.jokic-ssh.files."ssh_host_ed25519_key".path;
                  mountPoint = "/run/secrets/ssh";
                  tag = "ssh";
                  proto = "virtiofs";
                }
              ];
              microvm.volumes = [
                {
                  image = "./jokic-steam-share.img";
                  size = 200000; # MiB (200GB)
                  fsType = "ext4";
                  mountPoint = "/home/gamer/.local/share";
                }
              ];
              systemd.services.fix-steam-share-perms = {
                description = "Fix ownership of Steam share";
                wantedBy = [ "multi-user.target" ];
                after = [ "local-fs.target" ];
                serviceConfig = {
                  Type = "oneshot";
                  ExecStart = "${pkgs.coreutils}/bin/chown -R gamer:gamer /home/gamer/.local/share";
                };
              };

              microvm.interfaces = [
                {
                  id = "vm${toString index}";
                  type = "tap";
                  inherit mac;
                }
              ];

              microvm.devices = [
                {
                  # RTX 4080
                  bus = "pci";
                  path = "0000:01:00.0";
                }
                {
                  # GPU HDMI/DP audio
                  bus = "pci";
                  path = "0000:01:00.1";
                }
                {
                  # Keychron V6 keyboard
                  bus = "usb";
                  path = "vendorid=0x3434,productid=0x0361";
                }
                {
                  # Razer Viper Mini mouse
                  bus = "usb";
                  path = "vendorid=0x1532,productid=0x008a";
                }
              ];

              system.stateVersion = "25.11";

              users.users.root.openssh.authorizedKeys.keys = [
                "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJgiH4Iu1GUe9Hd40cSnQH94EHj0VmjXdbsaBED2WMHT colmena"
              ];

              networking.useNetworkd = true;

              systemd.network.networks."10-eth" = {
                matchConfig.MACAddress = mac;
                address = [
                  "10.0.0.${toString index}/32"
                ];
                routes = [
                  {
                    # Route to the host
                    Destination = "10.0.0.0/32";
                    GatewayOnLink = true;
                  }
                  {
                    # Default route
                    Destination = "0.0.0.0/0";
                    Gateway = "10.0.0.0";
                    GatewayOnLink = true;
                  }
                ];
                networkConfig = {
                  DNS = [ "192.168.1.1" ];
                };
              };
            };
        };
      };
    };
}
