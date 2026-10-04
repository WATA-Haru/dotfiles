{ pkgs, ... }:

{
    home.packages = with pkgs; [
      ghq
      ripgrep
      tmux
    ];
}
