{ pkgs, ... }:

{
    home.packages = with pkgs; [
      ghq
      ripgrep
      tmux
    ];

    home.sessionVariables = {
      EDITOR = "nvim";
      VISUAL = "nvim";
    };
}
