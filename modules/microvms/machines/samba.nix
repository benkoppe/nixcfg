{ self, ... }:
{
  flake.clan.machines.vm-samba =
    {
      pkgs,
      config,
      lib,
      ...
    }:
    let
      sambaUser = "samba";

      mountPath = "/mnt/files";
      familyPath = "${mountPath}/family";
      familySharedPath = "${familyPath}/shared";
      familyUsersPath = "${familyPath}/users";
      familyTimemachinePath = "${familyPath}/timemachine";

      familyUsers = [
        "ben"
        "greg"
      ];

      mkTimemachineShare = user: {
        name = "timemachine-${user}";
        value = {
          "path" = "${familyTimemachinePath}/${user}";
          "valid users" = user;
          "public" = "no";
          "browseable" = "yes";
          "read only" = "no";
          "writeable" = "yes";

          "force user" = sambaUser;
          "force group" = "users";

          "fruit:time machine" = "yes";
          "fruit:aapl" = "yes";
          "vfs objects" = "catia fruit streams_xattr";
        };
      };

      mkUserFileShare = user: {
        name = user;
        value = {
          "path" = "${familyUsersPath}/${user}";
          "valid users" = user;
          "browseable" = "yes";
          "read only" = "no";

          "create mask" = "0600";
          "directory mask" = "0700";
        };
      };
    in
    {
      imports = with self.modules.nixos; [
        microvms_client

        zabbix-agent
      ];

      microvm.shares = [
        {
          proto = "virtiofs";
          tag = "samba-files";
          source = "/tank0/files/samba";
          mountPoint = mountPath;
        }
      ];

      microvm.volumes = [
        {
          image = "/tank0/microvms/samba/samba-state.img";
          mountPoint = "/var/lib/samba";
          size = 256;
        }
      ];

      systemd.services.create-share-dirs = {
        wantedBy = [ "multi-user.target" ];
        after = [ "mnt-files.mount" ];
        requires = [ "mnt-files.mount" ];

        serviceConfig.Type = "oneshot";

        script = ''
          mkdir -p ${familySharedPath}
          mkdir -p ${familyUsersPath}
          mkdir -p ${familyTimemachinePath}

          chown root:family ${familyPath}
          chmod 0770 ${familyPath}

          chown root:family ${familySharedPath}
          chmod 2770 ${familySharedPath}

          chown root:family ${familyUsersPath}
          chmod 0750 ${familyUsersPath}

          ${lib.concatMapStringsSep "\n" (user: ''
            mkdir -p ${familyUsersPath}/${user}
            chown ${user}:family ${familyUsersPath}/${user}
            chmod 0700 ${familyUsersPath}/${user}

            mkdir -p ${familyTimemachinePath}/${user}
            chown ${sambaUser}:users ${familyTimemachinePath}/${user}
            chmod 0700 ${familyTimemachinePath}/${user}
          '') familyUsers}
        '';
      };

      systemd.services.samba-smbd = {
        after = [ "create-share-dirs.service" ];
        requires = [ "create-share-dirs.service" ];
      };

      clan.core.vars.generators =
        let
          mkUser = user: {
            name = "samba-${user}-user";
            value = {
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
          };
        in
        builtins.listToAttrs (map mkUser familyUsers);

      users.groups.family = { };
      users.users =
        let
          mkUser = user: {
            name = user;
            value = {
              extraGroups = [
                "users"
                "family"
              ];
              isNormalUser = true;
              hashedPasswordFile = config.clan.core.vars.generators."samba-${user}-user".files.password-hash.path;
            };
          };
        in
        {
          ${sambaUser} = {
            isNormalUser = true;
            extraGroups = [ "family" ];
          };
        }
        // builtins.listToAttrs (map mkUser familyUsers);

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
              + " 192.168.1." # home LAN
              + " 10.1.1." # dray proxmox
              + " 10.0.1." # luka proxmox
              + " 127.0.0.1 localhost";
            "hosts deny" = "0.0.0.0/0";
            "guest account" = "nobody";
            "map to guest" = "bad user";

            # macOS compatibility.
            "vfs objects" = "catia fruit streams_xattr";
            "fruit:aapl" = "yes";
            "fruit:metadata" = "stream";
            "fruit:resource" = "stream";
            "fruit:encoding" = "native";
          };

          "family" = {
            "path" = familySharedPath;
            "valid users" = "@family";
            "browseable" = "yes";
            "read only" = "no";

            # Important: no force user here.
            # This share relies on real Unix permissions.
            "create mask" = "0660";
            "directory mask" = "0770";
            "force group" = "family";
            "inherit permissions" = "yes";
            "inherit acls" = "yes";
            "hide unreadable" = "yes";
            "delete readonly" = "yes";
          };
        }
        // builtins.listToAttrs (map mkTimemachineShare familyUsers)
        // builtins.listToAttrs (map mkUserFileShare familyUsers);
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

        extraServiceFiles =
          let
            mkAdiskRecord =
              index: user: "<txt-record>dk${toString index}=adVN=timemachine-${user},adVF=0x82</txt-record>";

            adiskRecords = lib.concatStringsSep "\n" (lib.imap0 mkAdiskRecord familyUsers);
          in
          {
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
                  ${adiskRecords}
                  <txt-record>sys=waMa=0,adVF=0x100</txt-record>
                </service>
              </service-group>
            '';
          };
      };
    };
}
