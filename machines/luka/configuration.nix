{
  self,
  lib,
  pkgs,
  config,
  ...
}:
{
  imports = with self.modules.nixos; [
    nix
    self.inputs.microvm.nixosModules.host
  ];

  clan.core.vars.generators.luks-password = {
    prompts.password = {
      description = "LUKS password for machine luka";
      type = "hidden";
    };
    files.password = {
      secret = true;
      neededFor = "partitioning";
    };

    script = "cp $prompts/password $out/password";
  };

  boot.initrd.kernelModules = [
    "vfio_pci"
    "vfio"
    "vfio_iommu_type1"

    "amdgpu"
  ];
  boot.kernelParams = [
    "amd_iommu=on"
    "iommu=pt"
    "vfio-pci.ids=10de:2704,10de:22bb" # ensure vfio claims the 4080
  ];
  boot.blacklistedKernelModules = [
    "nouveau"
    "nvidia"
    "nvidia_drm"
    "nvidia_modeset"
  ];

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
          };
          users.groups.gamer = { };

          hardware.graphics.enable = true;
          services.xserver.videoDrivers = [ "nvidia" ];
          hardware.nvidia.open = true;

          boot.kernelParams = [ "nvidia-drm.modeset=1" ];

          programs.steam = {
            enable = true;
            gamescopeSession.enable = true;
          };
          programs.gamescope = {
            enable = true;
            capSysNice = true;
          };
          services.getty.autologinUser = "gamer";
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

          microvm.cpu = "host";
          microvm.vcpu = 8;
          microvm.mem = 16384;

          microvm.shares = [
            {
              source = "/nix/store";
              mountPoint = "/nix/.ro-store";
              tag = "ro-store";
              proto = "virtiofs";
            }
            {
              source =
                builtins.dirOf
                  config.clan.core.vars.generators.jokic-ssh.files."ssh_host_ed25519_key".path;
              mountPoint = "/run/secrets/ssh";
              tag = "ssh";
              proto = "virtiofs";
            }
          ];

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

}
