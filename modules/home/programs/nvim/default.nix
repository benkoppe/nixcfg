{
  config,
  lib,
  pkgs,
  self,
  ...
}:
{
  imports = [
    self.inputs.mnw.homeManagerModules.default
  ];

  options.myHome.programs.nvim.enable = lib.mkEnableOption "neovim";

  config = lib.mkIf config.myHome.programs.nvim.enable {
    programs.mnw = {
      enable = true;

      aliases = [
        "vi"
        "vim"
      ];

      providers = {
        ruby.enable = true;
        python3.enable = true;
        nodeJs.enable = true;
        perl.enable = true;
      };

      plugins = {
        start = [
          pkgs.vimPlugins.lazy-nvim
          pkgs.vimPlugins.plenary-nvim
        ];

        dev.myconfig = {
          pure = ./.;
          impure = "~/nixos-config/modules/shared/config/nvim/";
        };
      };

      luaFiles = [ ./init.lua ];

      extraBinPath = builtins.attrValues {
        inherit (pkgs)
          #
          # runtime dependencies
          #
          deadnix
          statix
          nixd
          nixfmt

          ripgrep
          fd
          fzf
          chafa
          tree-sitter

          # lua
          lua-language-server
          stylua

          prettierd

          # python
          black
          pyright
          ruff

          # go
          gopls
          gofumpt
          gotools

          # docker
          dockerfile-language-server
          docker-compose-language-service

          # webdev
          vscode-langservers-extracted
          svelte-language-server
          tailwindcss-language-server
          vue-language-server
          vtsls # typescript
          typescript-language-server
          javascript-typescript-langserver

          # rust
          rust-analyzer
          rustfmt
          lldb

          # clang
          clang-tools

          # random
          bash-language-server
          yaml-language-server

          # csharpier  # Disabled due to .NET build issues on macOS ARM64
          ktlint
          markdownlint-cli2
          rubocop
          shfmt
          sqlfluff
          ;
      };
    };
  };
}
