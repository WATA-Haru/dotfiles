{
  imports = [
    ../modules/cli.nix
    ../modules/common.nix
    ../modules/vim.nix
    ../modules/neovim.nix
    ../modules/zsh.nix
    ../modules/tmux.nix
    ../modules/git.nix
    ../modules/direnv.nix
  ];

  programs.home-manager.enable = true;
}
