{ lib, ... }:
let
  inherit (lib)
    concatMapStringsSep
    concatStringsSep
    hasAttr
    mapAttrsToList
    mkEnableOption
    mkIf
    mkOption
    optionalString
    types
    ;

  quote = s: ''"${s}"'';

  nftElements = values: "{ ${concatStringsSep ", " values} }";
  nftStringElements = values: nftElements (map quote values);

  vmToVmRuleType = types.submodule {
    options = {
      name = mkOption {
        type = types.str;
        description = "Human-readable rule name.";
      };

      from = mkOption {
        type = types.str;
        description = "Source VM name from my.service-vms.";
      };

      to = mkOption {
        type = types.str;
        description = "Destination VM name from my.service-vms.";
      };

      proto = mkOption {
        type = types.enum [
          "tcp"
          "udp"
        ];
        default = "tcp";
        description = "Protocol to allow.";
      };

      ports = mkOption {
        type = types.listOf types.port;
        description = "Destination ports to allow.";
      };
    };
  };

  vmToIpRuleType = types.submodule {
    options = {
      name = mkOption {
        type = types.str;
        description = "Human-readable rule name.";
      };

      from = mkOption {
        type = types.str;
        description = "Source VM name from my.service-vms.";
      };

      proto = mkOption {
        type = types.enum [
          "tcp"
          "udp"
        ];
        default = "tcp";
        description = "Protocol to allow.";
      };

      destinations = mkOption {
        type = types.listOf types.str;
        description = "Destination IPv4 addresses to allow.";
      };

      ports = mkOption {
        type = types.listOf types.port;
        description = "Destination ports to allow.";
      };
    };
  };
in
{
  flake.modules.nixos."microvms_host_firewall" =
    { config, ... }:
    let
      cfg = config.my.microvms.firewall;
      network = config.my.microvms.network;
      serviceVms = config.my.service-vms or { };

      vmInfo =
        name:
        let
          vm = serviceVms.${name};
          inherit (vm) id;
        in
        {
          inherit id;
          ip = "${network.subnet}.${toString id}";
          iface = "vm${toString id}";
        };

      vmIfaces = mapAttrsToList (_: vm: "vm${toString vm.id}") serviceVms;

      mkVmSourceMatch =
        rule:
        let
          from = vmInfo rule.from;
        in
        "iifname ${quote from.iface} ip saddr ${from.ip}";

      mkVmRule = rule: destinationMatch: ''
        ${mkVmSourceMatch rule} ${destinationMatch} ${rule.proto} dport ${nftElements (map toString rule.ports)} counter accept comment ${quote "microvm allow: ${rule.name}"}
      '';

      mkVmToVmRule =
        rule:
        let
          to = vmInfo rule.to;
        in
        mkVmRule rule "oifname ${quote to.iface} ip daddr ${to.ip}";

      mkVmToIpRule = rule: mkVmRule rule "ip daddr ${nftElements rule.destinations}";

      mkAntiSpoofRule =
        name: _:
        let
          vm = vmInfo name;
        in
        ''
          iifname ${quote vm.iface} ip saddr != ${vm.ip} counter drop comment ${quote "microvm anti-spoof: ${name}"}
        '';

      logPrefix = optionalString cfg.logDenied ''log prefix "microvm-fw drop: " flags all'';

      mkDropRule = match: comment: ''
        ${match} counter ${logPrefix} drop comment ${quote comment}
      '';

      vmToVmRules = concatMapStringsSep "\n        " mkVmToVmRule cfg.vmToVmRules;
      vmToIpRules = concatMapStringsSep "\n        " mkVmToIpRule cfg.vmToIpRules;
      antiSpoofRules = concatStringsSep "\n        " (mapAttrsToList mkAntiSpoofRule serviceVms);

      adminRule = optionalString (cfg.adminCidrs != [ ]) ''
        ip saddr @admin_v4 oifname @vm_ifaces counter accept comment "microvm allow: admin-to-vms"
      '';

      dnsRules = optionalString (cfg.dnsServers != [ ]) ''
        iifname @vm_ifaces ip daddr @dns_v4 udp dport 53 counter accept comment "microvm allow: vm-dns-udp"
        iifname @vm_ifaces ip daddr @dns_v4 tcp dport 53 counter accept comment "microvm allow: vm-dns-tcp"
      '';

      internetRule = optionalString cfg.allowVmInternet ''
        iifname @vm_ifaces oifname @wan_ifaces counter accept comment "microvm allow: vm-to-internet"
      '';
    in
    {
      options.my.microvms.firewall = {
        enable = mkEnableOption "nftables firewall for routed microVMs";

        wanInterfaces = mkOption {
          type = types.listOf types.str;
          default = [ network.externalInterface ];
          description = "Interfaces used for non-private internet egress.";
        };

        adminCidrs = mkOption {
          type = types.listOf types.str;
          default = [
            "192.168.1.0/24"
            "100.64.0.0/10"
          ];
          description = "Trusted source CIDRs allowed to reach VM services.";
        };

        privateCidrs = mkOption {
          type = types.listOf types.str;
          default = [
            "10.0.0.0/8"
            "100.64.0.0/10"
            "172.16.0.0/12"
            "192.168.0.0/16"
          ];
          description = "Private destinations blocked from VM egress before internet allow rules.";
        };

        dnsServers = mkOption {
          type = types.listOf types.str;
          default = [ "192.168.1.1" ];
          description = "Private DNS servers microVMs may reach.";
        };

        allowVmInternet = mkOption {
          type = types.bool;
          default = true;
          description = "Allow VM egress to non-private destinations through wanInterfaces.";
        };

        logDenied = mkOption {
          type = types.bool;
          default = false;
          description = "Log denied microVM forwarded traffic.";
        };

        vmToVmRules = mkOption {
          type = types.listOf vmToVmRuleType;
          default = [ ];
          description = "Explicit allowed VM-to-VM service dependencies.";
        };

        vmToIpRules = mkOption {
          type = types.listOf vmToIpRuleType;
          default = [ ];
          description = "Explicit allowed VM egress to IPv4 destinations.";
        };
      };

      config = mkIf cfg.enable {
        assertions =
          (map (rule: {
            assertion = hasAttr rule.from serviceVms && hasAttr rule.to serviceVms;
            message = "my.microvms.firewall rule '${rule.name}' references an unknown VM.";
          }) cfg.vmToVmRules)
          ++ (map (rule: {
            assertion = hasAttr rule.from serviceVms;
            message = "my.microvms.firewall rule '${rule.name}' references an unknown source VM.";
          }) cfg.vmToIpRules);

        networking.nftables.enable = true;

        networking.nftables.tables.microvm-filter = {
          family = "inet";
          content = ''
            set vm_ifaces {
              type ifname
              elements = ${nftStringElements vmIfaces}
            }

            set wan_ifaces {
              type ifname
              elements = ${nftStringElements cfg.wanInterfaces}
            }

            set admin_v4 {
              type ipv4_addr
              flags interval
              elements = ${nftElements cfg.adminCidrs}
            }

            set private_v4 {
              type ipv4_addr
              flags interval
              elements = ${nftElements cfg.privateCidrs}
            }

            set dns_v4 {
              type ipv4_addr
              elements = ${nftElements cfg.dnsServers}
            }

            chain forward {
              type filter hook forward priority -50; policy accept;

              ct state established,related counter accept comment "microvm allow: established related"

              ${antiSpoofRules}

              ${vmToVmRules}

              ${vmToIpRules}

              ${adminRule}

              ${dnsRules}

              ${mkDropRule "iifname @vm_ifaces oifname @vm_ifaces" "microvm deny: vm-to-vm default deny"}

              ${mkDropRule "iifname @vm_ifaces ip daddr @private_v4" "microvm deny: vm-to-private default deny"}

              ${internetRule}

              ${mkDropRule "iifname @vm_ifaces" "microvm deny: vm-forward fallback"}

              ${mkDropRule "oifname @vm_ifaces" "microvm deny: to-vm fallback"}
            }
          '';
        };
      };
    };
}
