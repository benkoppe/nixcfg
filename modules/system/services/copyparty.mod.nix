{ inputs, ... }:
{
  flake.modules.nixos.copyparty = {
    imports = [ inputs.copyparty.nixosModules.default ];

    nixpkgs.overlays = [ inputs.copyparty.overlays.default ];

    services.copyparty = {
      enable = true;

      settings = {
        i = "0.0.0.0";
        p = [ 3210 ];

        hist = "/var/lib/copyparty";
      };
      volumes = {
        "/" = {
          path = "/tank0/files/taildrive";
          access = {
            r = "*";
          };
          flags = {
            # "fk" enables filekeys (necessary for upget permission) (4 chars long)
            fk = 4;
            # scan for new files every 60sec
            scan = 60;
            # volflag "e2d" enables the uploads database
            e2d = true;
            # "d2t" disables multimedia parsers (in case the uploads are malicious)
            d2t = false;
            # skips hashing file contents if path matches *.iso
            nohash = "\.iso$";
          };
        };
      };
      openFilesLimit = 8192;
    };
  };
}
