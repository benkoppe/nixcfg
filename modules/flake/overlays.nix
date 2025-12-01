{ self, ... }:
{
  flake = {
    defaultOverlays = [ self.overlays.personalGlance ];

    overlays = {
      personalGlance = final: prev: {
        glance = prev.glance.overrideAttrs (old: {
          version = "0.8.4-personal";

          src = prev.fetchFromGitHub {
            owner = "benkoppe";
            repo = "glance";
            rev = "monitor-descriptions";
            hash = "sha256-nOltrNS9RSyIuNC2x42q94/I7BxPMDsQlZYOu3CAG54=";
          };
        });
      };
    };
  };
}
