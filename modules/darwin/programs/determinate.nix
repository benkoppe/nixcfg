{
  config,
  lib,
  self,
  ...
}:
{
  options.myDarwin.programs.determinate = {
    enable = lib.mkEnableOption "sane determinate-nix configuration";

    accessTokens.enable = lib.mkEnableOption "use access tokens for github private inputs access";
  };

  config = lib.mkIf config.myDarwin.programs.determinate.enable (
    lib.mkMerge [
      {
        nix.enable = false;

        determinate-nix.customSettings = lib.mkMerge [
          config.mySnippets.nix.settings
          {
            eval-cores = 0;
          }
          (
            let
              # convert normal nix buildMachines config to determinate string format
              builderToString =
                b:
                let
                  # safely get an attribute or fallback
                  get =
                    name: default:
                    if builtins.hasAttr name b then
                      let
                        val = builtins.getAttr name b;
                      in
                      if val == "" || val == [ ] then default else val
                    else
                      default;

                  hostName = get "hostName" "-";
                  sshUser = get "sshUser" "-";
                  protocol = get "protocol" "ssh";
                  uri =
                    if sshUser == "-" then "${protocol}://${hostName}" else "${protocol}://${sshUser}@${hostName}";

                  systems = builtins.concatStringsSep "," (get "systems" [ "-" ]);
                  sshKey = get "sshKey" "-";
                  maxJobs = toString (get "maxJobs" "-");
                  speedFactor = toString (get "speedFactor" "-");
                  supportedFeatures = builtins.concatStringsSep "," (get "supportedFeatures" [ "-" ]);
                  mandatoryFeatures = builtins.concatStringsSep "," (get "mandatoryFeatures" [ "-" ]);
                  publicHostKey = get "publicHostKey" "-";
                in
                "${uri} ${systems} ${sshKey} ${maxJobs} ${speedFactor} ${supportedFeatures} ${mandatoryFeatures} ${publicHostKey}";
            in
            {
              builders = builtins.concatStringsSep " ; " (
                map builderToString config.mySnippets.nix.buildMachines
              );
            }
          )
        ];
      }

      (lib.mkIf config.myDarwin.programs.determinate.accessTokens.enable {
        environment.etc."nix/nix.custom.conf".text =
          lib.mkAfter "!include ${config.age.secrets.access-tokens.path}";

        age.secrets.access-tokens = {
          file = "${self.inputs.secrets}/programs/nix/access-tokens.age";
          symlink = false;
          mode = "444";
        };
      })
    ]
  );
}
