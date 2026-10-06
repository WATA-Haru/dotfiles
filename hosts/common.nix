{
  imports = [
    ../modules/cli.nix
    ../modules/common.nix
    ../modules/neovim.nix
    ../modules/zsh.nix
    ../modules/tmux.nix
  ];

  programs.home-manager.enable = true;
}
