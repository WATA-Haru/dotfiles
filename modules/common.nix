{ pkgs, ... }:

{
    home.packages = with pkgs; [
      ghq
      neovim
      ripgrep
      tmux
    ];

    home.sessionVariables = {
      EDITOR = "nvim";
      VISUAL = "nvim";
    };
}
