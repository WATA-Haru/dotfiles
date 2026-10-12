{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    vim
    neovim
    ghostty.terminfo
  ];
}
