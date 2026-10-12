{ config, ... }:

{
  programs.zsh = {
    enable = true;
    dotDir = config.home.homeDirectory;
    enableCompletion = true;

    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;

    defaultKeymap = "viins";

    history = {
      size = 100000;
      save = 100000;
      extended = true;
      ignoreDups = true;
      ignoreSpace = true;
      share = true;
    };

    shellAliases = {
      ll = "ls -alF";
      la = "ls -A";
      lla = "ls -la";
      gs = "git status";
      c = "clear";
      n = "nvim";
    };

    initContent = builtins.readFile ../dot_config/zsh/functions.zsh;
  };

  programs.fzf = {
    enable = true;
    enableZshIntegration = true;
  };
}
