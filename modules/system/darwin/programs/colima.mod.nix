{
  flake.modules.hjem.colima =
    { pkgs, config, ... }:
    {
      packages = [
        pkgs.colima
      ];

      environment.sessionVariables = {
        COLIMA_HOME = "${config.xdg.config.directory}/colima";
        LIMA_HOME = "${config.xdg.config.directory}/lima";
      };
    };
}
