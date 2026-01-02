let
  dnsPort = 53;
  home_ipv4 = "192.168.1.200";
  vHost = "adguard.thekoppe.com";
  username = "ben";
in
{
  flake.modules.nixos.adguard =
    { pkgs, config, ... }:
    {
      config = {
        clan.core.vars.generators.adguard-password = {
          prompts.password-input = {
            description = "Password for the adguard user '${username}'";
            type = "hidden";
            persist = false;
          };
          files.password-hash.secret = false;
          script = ''
            cat $prompts/password-input \
              | htpasswd -B -C 10 -n -i "${username}" \
              | cut -d':' -f2- \
              > $out/password-hash
          '';
          runtimeInputs = [ pkgs.apacheHttpd ];
        };

        my.service-vms.adguard.modules = [
          {
            microvm.volumes = [
              {
                image = "adguard-data.img";
                mountPoint = "/var/lib/private/AdGuardHome";
                size = 64;
              }
            ];

            services.resolved.enable = false;

            networking.firewall = {
              allowedTCPPorts = [ dnsPort ];
              allowedUDPPorts = [ dnsPort ];
            };

            services.adguardhome = {
              enable = true;
              port = 3000;
              openFirewall = true;

              mutableSettings = false;
              settings = {
                http = {
                  pprof = {
                    port = 6060;
                    enabled = false;
                  };
                  session_ttl = "720h";
                };
                users = [
                  {
                    name = username;
                    password = config.clan.core.vars.generators.adguard-password.files.password-hash.value;
                  }
                ];
                auth_attempts = 5;
                block_auth_min = 15;
                http_proxy = "";
                language = "";
                theme = "auto";
                dns = {
                  port = dnsPort;
                  bind_hosts = [ "0.0.0.0" ];
                  anonymize_client_ip = true;
                  ratelimit = 20;
                  ratelimit_subnet_len_ipv4 = 24;
                  ratelimit_subnet_len_ipv6 = 56;
                  ratelimit_whitelist = [ ];
                  refuse_any = true;
                  upstream_dns = [
                    "https://dns10.quad9.net/dns-query"
                    "1.1.1.1"
                  ];
                  upstream_dns_file = "";
                  bootstrap_dns = [
                    "9.9.9.10"
                    "149.112.112.10"
                    "2620:fe::10"
                    "2620:fe::fe:10"
                  ];
                  fallback_dns = [ "8.8.8.8" ];
                  upstream_mode = "load_balance";
                  fastest_timeout = "1s";
                  allowed_clients = [ ];
                  disallowed_clients = [ ];
                  blocked_hosts = [
                    "version.bind"
                    "id.server"
                    "hostname.bind"
                  ];
                  trusted_proxies = [
                    "127.0.0.0/8"
                    "::1/128"
                  ];
                  cache_enabled = true;
                  cache_size = 4194304;
                  cache_ttl_min = 0;
                  cache_ttl_max = 0;
                  cache_optimistic = false;
                  bogus_nxdomain = [ ];
                  aaaa_disabled = false;
                  enable_dnssec = false;
                  edns_client_subnet = {
                    custom_ip = "";
                    enabled = false;
                    use_custom = false;
                  };
                  max_goroutines = 300;
                  handle_ddr = true;
                  ipset = [ ];
                  ipset_file = "";
                  bootstrap_prefer_ipv6 = false;
                  upstream_timeout = "10s";
                  private_networks = [ ];
                  use_private_ptr_resolvers = true;
                  local_ptr_upstreams = [ ];
                  use_dns64 = false;
                  dns64_prefixes = [ ];
                  serve_http3 = false;
                  use_http3_upstreams = false;
                  serve_plain_dns = true;
                  hostsfile_enabled = true;
                  pending_requests = {
                    enabled = true;
                  };
                };
                tls = {
                  enabled = false;
                  server_name = "";
                  force_https = false;
                  port_https = 443;
                  port_dns_over_tls = 853;
                  port_dns_over_quic = 853;
                  port_dnscrypt = 0;
                  dnscrypt_config_file = "";
                  allow_unencrypted_doh = false;
                  certificate_chain = "";
                  private_key = "";
                  certificate_path = "";
                  private_key_path = "";
                  strict_sni_check = false;
                };
                querylog = {
                  dir_path = "";
                  ignored = [ ];
                  interval = "1h";
                  size_memory = 1000;
                  enabled = true;
                  file_enabled = true;
                };
                statistics = {
                  dir_path = "";
                  ignored = [ ];
                  interval = "168h";
                  enabled = true;
                };
                filters = [
                  {
                    enabled = true;
                    url = "https://adguardteam.github.io/HostlistsRegistry/assets/filter_1.txt";
                    name = "AdGuard DNS filter";
                    id = 1;
                  }
                  {
                    enabled = false;
                    url = "https://adguardteam.github.io/HostlistsRegistry/assets/filter_2.txt";
                    name = "AdAway Default Blocklist";
                    id = 2;
                  }
                ];
                whitelist_filters = [ ];
                user_rules = [
                  "@@||umami.is^$important"
                  "@@||api.us-east-1.aiv-delivery.net^$important"
                  ""
                ];
                dhcp = {
                  enabled = false;
                  interface_name = "";
                  local_domain_name = "lan";
                  dhcpv4 = {
                    gateway_ip = "";
                    subnet_mask = "";
                    range_start = "";
                    range_end = "";
                    lease_duration = 86400;
                    icmp_timeout_msec = 1000;
                    options = [ ];
                  };
                  dhcpv6 = {
                    range_start = "";
                    lease_duration = 86400;
                    ra_slaac_only = false;
                    ra_allow_slaac = false;
                  };
                };
                filtering = {
                  blocking_ipv4 = "";
                  blocking_ipv6 = "";
                  blocked_services = {
                    schedule = {
                      time_zone = "Local";
                    };
                    ids = [ ];
                  };
                  protection_disabled_until = null;
                  safe_search = {
                    enabled = false;
                    bing = true;
                    duckduckgo = true;
                    ecosia = true;
                    google = true;
                    pixabay = true;
                    yandex = true;
                    youtube = true;
                  };
                  blocking_mode = "default";
                  parental_block_host = "family-block.dns.adguard.com";
                  safebrowsing_block_host = "standard-block.dns.adguard.com";
                  rewrites = [
                    {
                      domain = "${vHost}";
                      answer = "${home_ipv4}";
                    }
                    {
                      domain = "tang.home";
                      answer = "192.168.1.104";
                    }
                    {
                      domain = "tang-2.home";
                      answer = "192.168.1.112";
                    }
                    {
                      domain = "fileserver.thekoppe.com";
                      answer = "192.168.1.61";
                    }
                    {
                      domain = "pve.local";
                      answer = "192.168.1.100";
                    }
                    {
                      domain = "tang-1.home";
                      answer = "192.168.1.104";
                    }
                  ];
                  safe_fs_patterns = [ "/opt/AdGuardHome/userfilters/*" ];
                  safebrowsing_cache_size = 1048576;
                  safesearch_cache_size = 1048576;
                  parental_cache_size = 1048576;
                  cache_time = 30;
                  filters_update_interval = 24;
                  blocked_response_ttl = 10;
                  filtering_enabled = true;
                  parental_enabled = false;
                  safebrowsing_enabled = false;
                  protection_enabled = true;
                };
                clients = {
                  runtime_sources = {
                    whois = true;
                    arp = true;
                    rdns = true;
                    dhcp = true;
                    hosts = true;
                  };
                  persistent = [ ];
                };
                log = {
                  enabled = true;
                  file = "";
                  max_backups = 0;
                  max_size = 100;
                  max_age = 3;
                  compress = false;
                  local_time = false;
                  verbose = false;
                };
                os = {
                  group = "";
                  user = "";
                  rlimit_nofile = 0;
                };
                schema_version = 30;
              };
            };

          }
        ];
      };
    };
}
