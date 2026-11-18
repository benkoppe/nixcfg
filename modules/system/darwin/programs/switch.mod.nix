{ inputs, ... }:
{
  # Switch window switcher (https://github.com/Sanyam-G/switch), installed from
  # the upstream tap so it keeps its notarized Developer ID signature and
  # Accessibility / Screen Recording grants survive updates.
  flake.modules.darwin.switch = {
    nix-homebrew = {
      taps."Sanyam-G/homebrew-switch" = inputs.homebrew-switch;
      trust.casks = [ "sanyam-g/switch/switch" ];
    };

    homebrew.casks = [
      {
        name = "sanyam-g/switch/switch";
        greedy = true;
      }
    ];

    # Versions come from the pinned tap; stop Sparkle updating behind brew's back.
    system.defaults.CustomUserPreferences."com.sanyamgarg.switch".SUEnableAutomaticChecks = false;
  };
}
