_: {
  perSystem =
    { pkgs, ... }:
    {
      packages = {
        herdr-autoname = pkgs.callPackage ./herdr-autoname { };
      };
    };
}
