{
  lib,
  config,
  self,
  pkgs,
  ...
}:
{
  options.myHome.programs.nvim.enable = lib.mkEnableOption "neovim";

  config = lib.mkIf config.myHome.programs.nvim.enable {
    home.packages = [
      self.inputs.nvim-flake.packages.${pkgs.stdenv.hostPlatform.system}.default
    ];
  };
}
