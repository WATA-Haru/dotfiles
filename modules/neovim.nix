{ pkgs, ... }:

let
  vueLanguageServerRoot =
    "${pkgs.vue-language-server}/lib/language-tools/packages/language-server";
in
{
  programs.neovim = {
    enable = true;
    defaultEditor = true;
    viAlias = true;
    vimAlias = true;

    extraPackages = with pkgs; [
      # nvim-treesitter
      curl
      gnutar
      stdenv.cc
      tree-sitter

      # lsp
      emmet-language-server
      lua-language-server
      marksman
      pyright
      vtsls
      vue-language-server
    ];

    extraWrapperArgs = [
      "--set"
      "VUE_LANGUAGE_SERVER_PATH"
      vueLanguageServerRoot
    ];
  };

  xdg.configFile."nvim".source = ../dot_config/nvim;
}

