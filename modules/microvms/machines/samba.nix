{ self, ... }:
{
  flake.clan.machines.vm-samba =
    { pkgs, config, ... }:
    let
      sambaUser = "samba";
      benUser = "ben";

      mountPath = "/mnt/files";
      tmPath = "${mountPath}/timemachine";
    in
    {
      imports = with self.modules.nixos; [
        microvms_client
      ];

      microvm.shares = [
        {
          proto = "virtiofs";
          tag = "samba-files";
          source = "/tank0/files/samba";
          mountPoint = mountPath;
        }
      ];

      systemd.services.create-share-dirs = {
        wantedBy = [ "multi-user.target" ];
        after = [ "mnt-files.mount" ];
        requires = [ "mnt-files.mount" ];

        serviceConfig.Type = "oneshot";

        script = ''
          mkdir -p ${tmPath}
          chown ${sambaUser}:users ${tmPath}
          chmod 0755 ${tmPath}
        '';
      };

      systemd.services.samba-smbd = {
        after = [ "create-share-dirs.service" ];
        requires = [ "create-share-dirs.service" ];
      };

      clan.core.vars.generators =
        let
          mkUser = user: {
            share = true;
            prompts.password-value = {
              description = "Password for ${user}";
              type = "hidden";
              persist = false;
            };
            files.password-hash.secret = false;
            script = ''
              cat $prompts/password-value | mkpasswd > $out/password-hash
            '';
            runtimeInputs = [ pkgs.mkpasswd ];
          };
        in
        {
          samba-ben-user = mkUser benUser;
        };

      users.users = {
        ${sambaUser}.isNormalUser = true;

        ${benUser} = {
          extraGroups = [ "users" ];
          isNormalUser = true;
          hashedPasswordFile = config.clan.core.vars.generators.samba-ben-user.files.password-hash.path;
        };
      };

      services.samba = {
        enable = true;
        openFirewall = true;

        settings = {
          global = {
            "workgroup" = "WORKGROUP";
            "server string" = "smbnix";
            "netbios name" = "smbnix";
            "security" = "user";

            # Only available on localhost and Tailscale
            # note: localhost is the ipv6 localhost ::1
            "hosts allow" =
              "10.1.0.0" # host bridge running tailscale
              + " 100.64.0.0/10" # normal tailscale range
              + " 127.0.0.1 localhost";
            "hosts deny" = "0.0.0.0/0";
            "guest account" = "nobody";
            "map to guest" = "bad user";
          };

          "timemachine" = {
            "path" = tmPath;
            "valid users" = "${benUser}";
            "public" = "no";
            "writeable" = "yes";
            "force user" = sambaUser;
            "force group" = "users";
            # macOS compat, do not change
            "fruit:aapl" = "yes";
            "fruit:time machine" = "yes";
            "vfs objects" = "catia fruit streams_xattr";
          };
        };
      };

      services.samba-wsdd = {
        enable = true;
        openFirewall = true;
      };

      # Ensure Time Machine can discover the share without `tmutil`
      services.avahi = {
        enable = true;
        openFirewall = true;

        publish.enable = true;
        publish.userServices = true;
        nssmdns4 = true;

        extraServiceFiles = {
          timemachine = ''
            <?xml version="1.0" standalone='no'?>
            <!DOCTYPE service-group SYSTEM "avahi-service.dtd">
            <service-group>
              <name replace-wildcards="yes">%h</name>
              <service>
                <type>_smb._tcp</type>
                <port>445</port>
              </service>
                <service>
                <type>_device-info._tcp</type>
                <port>0</port>
                <txt-record>model=TimeCapsule8,119</txt-record>
              </service>
              <service>
                <type>_adisk._tcp</type>
                <!--
                  change to share name, if you changed it.
                -->
                <txt-record>dk0=adVN=timemachine,adVF=0x82</txt-record>
                <txt-record>sys=waMa=0,adVF=0x100</txt-record>
              </service>
            </service-group>
          '';
        };
      };
    };
}
