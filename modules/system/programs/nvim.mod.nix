{ inputs, ... }:
{
  flake.modules.hjem.nvim =
    { pkgs, lib, ... }:
    let
      inherit (pkgs.stdenv.hostPlatform) system;

      nvimPkgs = inputs.nvim-flake.packages.${system};
      # TODO: remove once nixpkgs fixes diff-cover's HTML report tests.
      # Pass the system's diff-cover test workaround to Neovim.
      withSystemPkgs = package: package.wrap { _module.args.pkgs = lib.mkForce pkgs; };
    in
    {
      packages = [
        (withSystemPkgs nvimPkgs.full)
        (withSystemPkgs nvimPkgs.minimal)
      ];

      environment.sessionVariables = {
        ALTERNATE_EDITOR = "";
        EDITOR = "vi";
        VISUAL = "nvim";
      };
    };

}
