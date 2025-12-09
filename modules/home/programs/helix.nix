{
  lib,
  config,
  pkgs,
  ...
}:
let
  baseLanguageMap = {
    astro = "astro";
    css = "css";
    html = "html";
    javascript = "js";
    jsonc = "jsonc";
    jsx = "jsx";
    markdown = "md";
    scss = "scss";
    svelte = "svelte";
    tsx = "tsx";
    typescript = "ts";
    vue = "vue";
    yaml = "yaml";
  };

  mappedLanguages = lib.mapAttrs (
    name: extension:
    {
      inherit name;
      auto-format = true;
      formatter.command = "deno";
      formatter.args = [
        "fmt"
        "--unstable-component"
        "--ext"
        extension
        "-"
      ];
    }
    //
      lib.optionalAttrs
        (lib.elem name [
          "javascript"
          "jsx"
          "typescript"
          "tsx"
        ])
        {
          language-servers = [ "deno" ];
        }
  ) baseLanguageMap;

  languageList = lib.attrValues mappedLanguages;

  extraLanguages = [
    {
      name = "nix";
      auto-format = true;
      formatter.command = "nixfmt";
    }

    {
      name = "python";
      auto-format = true;
      language-servers = [ "basedpyright" ];
    }

    {
      name = "toml";
      auto-format = true;
    }

    {
      name = "rust";

      debugger.name = "lldb-dap";
      debugger.transport = "stdio";
      debugger.command = "lldb-dap";
    }
  ];

  formattedLanguages = languageList ++ extraLanguages;

  lspConfigs = lib.mkValue {
    deno = {
      command = "deno";
      args = [ "lsp" ];

      environment.NO_COLOR = "1";

      config.javascript = {
        enable = true;
        lint = true;
        unstable = true;

        suggest.imports.hosts."https://deno.land" = true;

        inlayHints.enumMemberValues.enabled = true;
        inlayHints.functionLikeReturnTypes.enabled = true;
        inlayHints.parameterNames.enabled = "all";
        inlayHints.parameterTypes.enabled = true;
        inlayHints.propertyDeclarationTypes.enabled = true;
        inlayHints.variableTypes.enabled = true;
      };
    };

    rust-analyzer = {
      config = {
        cargo.features = "all";
        check.command = "clippy";
        completion.callable.snippets = "add_parentheses";
        completion.excludeTraits = [ "yansi::Paint" ];
        diagnostics.disabled = [
          "inactive-code"
          "unlinked-file"
        ];
      };
    };
  };
in
{
  options.myHome.programs.helix.enable = lib.mkEnableOption "helix editor";

  config = lib.mkIf config.myHome.programs.helix.enable {
    programs.helix = {
      enable = true;

      package = pkgs.evil-helix;

      settings = {
        theme = "tokyonight";

        editor = {
          line-number = "relative";
          file-picker.hidden = false;

          cursor-shape = {
            insert = "bar";
            normal = "block";
            select = "underline";
          };

    statusline.mode = {
            insert = "INSERT";
            normal = "NORMAL";
            select = "SELECT";
          };
        };
        keys.normal = {
          space.w = ":w";
          space.q = ":q";
        };
      };

      extraPackages = with pkgs; [
        # CMAKE
        cmake-language-server

        # GO
        gopls

        # HTML
        vscode-langservers-extracted

        # KOTLIN
        kotlin-language-server

        # LATEX
        texlab

        # LUA
        lua-language-server

        # MARKDOWN
        markdown-oxide

        # NIX
        nixfmt-rfc-style
        nixd

        # PYTHON
        basedpyright

        # RUST
        # rust-analyzer-nightly
        lldb

        # TYPESCRIPT & OTHERS
        deno

        # YAML
        yaml-language-server

        # ZIG
        zls
      ];
    };
  };
}
