{ config, lib, ... }:
{
  options.myDarwin.programs.determinate.enable =
    lib.mkEnableOption "sane determinate-nix configuration";

  config = lib.mkIf config.myDarwin.programs.determinate.enable {
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
  };
}
