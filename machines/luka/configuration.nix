{
  self,
  pkgs,
  config,
  ...
}:
{
  imports = with self.modules.nixos; [
    basics
    luks-encrypt
    boot_limine
    network_lan
    self.inputs.nixos-vfio.nixosModules.vfio
    proxmox
    tailgate

    ./microvms.nix
  ];

  services.vnstat.enable = true;

  swapDevices = [
    {
      device = "/var/lib/swapfile";
      size = 16 * 1024; # MiB
    }
  ];

  my.networking.lan = {
    enable = true;
    interface = "enp6s0";
    address = "192.168.1.100";
  };

  clan.core.vars.generators = {
    ups-primary-password = {
      files.value.secret = true;
      script = "openssl rand -base64 48 > $out/value";
      runtimeInputs = with pkgs; [
        openssl
      ];
      share = true;
    };
    ups-secondary-password = {
      files.value.secret = true;
      script = "openssl rand -base64 48 > $out/value";
      runtimeInputs = with pkgs; [
        openssl
      ];
      share = true;
    };
  };

  power.ups = {
    enable = true;
    mode = "netserver";

    ups."apc-smart-620" = {
      driver = "apcsmart";
      port = "/dev/serial/by-id/usb-Keyspan__a_division_of_InnoSys_Inc._Keyspan_USA-19H-if00-port0";
      description = "APC Smart-UPS 620";
      directives = [
        "ignorelb"
        "override.battery.runtime.low = 900"
      ];
    };

    users = {
      primary-client = {
        passwordFile = config.clan.core.vars.generators.ups-primary-password.files.value.path;
        upsmon = "primary";
      };
      secondary-client = {
        passwordFile = config.clan.core.vars.generators.ups-secondary-password.files.value.path;
        upsmon = "secondary";
      };
    };

    upsd.listen = [
      {
        address = "127.0.0.1";
      }
      {
        address = "192.168.1.100";
      }
    ];

    upsmon = {
      monitor."apc-smart-620" = {
        user = "primary-client";
        type = "primary";
      };

      settings.HOSTSYNC = 300;
    };
  };

  networking.firewall.interfaces.enp6s0.allowedTCPPorts = [ 3493 ];

  users.users.nutmon.extraGroups = [ "dialout" ];

  my.proxmox.id = 2;

  my.tailgate.routes = [
    "10.0.0.0/24"
    "10.0.1.0/24"
  ];

  hardware.graphics.enable = true;
  services.xserver.videoDrivers = [ "amdgpu" ];

  services.xserver.enable = true;
  services.displayManager.sddm.enable = true;
  services.displayManager.sddm.wayland.enable = true;
  services.desktopManager.plasma6.enable = true;
  environment.plasma6.excludePackages = with pkgs.kdePackages; [
    elisa
    khelpcenter
    krdp
  ];

  boot.kernelPackages = pkgs.linuxPackages_latest;

  virtualisation.libvirtd = {
    enable = true;
    onBoot = "ignore";
    sshProxy = false;
    qemu.swtpm.enable = true;
    deviceACL = [
      "/dev/kvm"
      "/dev/kvmfr0"
      "/dev/kvmfr1"
      "/dev/kvmfr2"
      "/dev/shm/scream"
      "/dev/shm/looking-glass"
      "/dev/null"
      "/dev/full"
      "/dev/zero"
      "/dev/random"
      "/dev/urandom"
      "/dev/ptmx"
      "/dev/kvm"
      "/dev/kqemu"
      "/dev/rtc"
      "/dev/hpet"
      "/dev/vfio/vfio"
    ];
  };
  virtualisation.spiceUSBRedirection.enable = true;
  virtualisation.vfio = {
    enable = true;
    IOMMUType = "amd";
    devices = [
      "10de:2704" # RTX 4080
      "10de:22bb" # HDMI/DP audio
    ];
    blacklistNvidia = true;
    disableEFIfb = true;
  };
  # virtualisation.hugepages = {
  #   enable = true;
  #   pageSize = "1G";
  #   numPages = 16; # match guest RAM
  # };
  virtualisation.kvmfr = {
    enable = true;
    devices = [
      {
        size = 128; # MB
        permissions = {
          user = "microvm";
          mode = "0777";
        };
      }
    ];
  };
  environment.systemPackages = with pkgs; [
    virtiofsd
    looking-glass-client
  ];
  services.udev.packages = with pkgs; [
    vial
    via
  ];
}
