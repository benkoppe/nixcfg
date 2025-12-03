{
  lib,
  config,
  inputs',
  ...
}:
{
  options.myHome.programs.nvim.enable = lib.mkEnableOption "neovim";

  config = lib.mkIf config.myHome.programs.nvim.enable {
    home.packages = [
      inputs'.nvim-flake.packages.default
    ];
  };
}
