_: {
  perSystem =
    { pkgs, ... }:
    {
      packages = {
        herdr-autoname = pkgs.callPackage ./herdr-autoname { };
        herdr-pluck = pkgs.callPackage ./herdr-pluck { };
      };
    };
}
