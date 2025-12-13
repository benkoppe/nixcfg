{
  config,
  inputs,
  pkgs,
  ...
}:
let
  inherit (config.mySnippets) hosts networks hostName;
  inherit (hosts.${hostName}) vHost;
in
{
  myNixOS = {
    profiles.proxmox-lxc.enable = true;

    services.caddy = {
      enable = true;

      networkDevices = [
        networks.tailscale.deviceName
      ];

      virtualHosts = [
        {
          inherit vHost;
          port = config.services.grafana.settings.server.http_port;
        }
      ];
    };
  };

  services.grafana = {
    enable = true;

    declarativePlugins = with pkgs.grafanaPlugins; [ grafana-clock-panel ];

    settings = {
      server = {
        http_addr = "";
        root_url = "https://${vHost}";
      };

      auth.disable_login_form = true;

      "auth.generic_oauth" = {
        enabled = true;
        allow_sign_up = true;
        auto_login = false;
        team_ids = "";
        allowed_organizations = "";
        name = "Pocket ID";
        client_id = "$__file{${config.age.secrets.grafana-oauth-client-id.path}}";
        client_secret = "$__file{${config.age.secrets.grafana-oauth-client-secret.path}}";
        scopes = "openid profile email";
        auth_url = "https://${hosts.pocket-id.vHost}/authorize";
        token_url = "https://${hosts.pocket-id.vHost}/api/oidc/token";
        use_pkce = true;
        use_refresh_token = true;

        email_attribute_name = "email:primary";
        skip_org_role_sync = true;
      };
    };
  };

  age.secrets =
    let
      common = secretFile: {
        file = secretFile;
        owner = "grafana";
        group = "grafana";
        mode = "440";
      };
    in
    {
      grafana-oauth-client-id = common "${inputs.secrets}/services/grafana/oauth-client-id.age";
      grafana-oauth-client-secret = common "${inputs.secrets}/services/grafana/oauth-secret.age";
    };
}
