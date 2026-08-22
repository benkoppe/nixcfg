_: {
  perSystem =
    { pkgs, ... }:
    {
      packages = {
        herdr-automatic-rename = pkgs.callPackage ./herdr-automatic-rename { };
      };
    };
}
