{ ... }:

{
  programs.vim = {
    enable = true;
    defaultEditor = true;
    extraConfig = builtins.readFile ../dot_config/.vimrc;
  };
}

