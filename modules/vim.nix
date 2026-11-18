{ lib, ... }:

{
  programs.vim = {
    enable = true;
    defaultEditor = true;
    plugins = lib.mkForce [];
    # extraConfig = builtins.readFile ../dot_config/.vimrc;
    extraConfig = ''
      execute 'source' . fnameescape(
       \ expand('$HOME/ghq/github.com/WATA-Haru/dotfiles/dot_config/.vimrc')
       \)
    '';
  };
}
