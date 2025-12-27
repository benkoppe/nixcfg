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

          hardware.graphics.enable = true;
          services.xserver.videoDrivers = [ "nvidia" ];
          hardware.nvidia.open = true;

          services.displayManager = {
            enable = true;
            sddm = {
              enable = true;
              wayland.enable = true;
            };
          };
          services.desktopManager.plasma6.enable = true;
          environment.plasma6.excludePackages = with pkgs.kdePackages; [
            elisa
            khelpcenter
            krdp
          ];

          microvm.mem = 8192;

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
