{
  flake = {
    herculesCI = _: {
      ciSystems = [
        "aarch64-linux"
        "x86_64-linux"
      ];
    };
  };
}
