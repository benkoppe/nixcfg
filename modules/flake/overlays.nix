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
            hash = "sha256-hrIC0NRZVlrZeSy0PdgL7Sqdb3IeYwbT7VZ5jSfQENE=";
          };
        });
      };
    };
  };
}
