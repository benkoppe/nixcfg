{
  flake.modules.hjem.herdr = { pkgs, ... }: {
    packages = [
      pkgs.herdr
    ];
  };
}
