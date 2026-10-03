{
  imports = [
    ../modules/common.nix
    ../modules/zsh.nix
  ];

  home.username = "hwata";
  home.homeDirectory = "/home/hwata";
  home.stateVersion = "26.05";

  programs.home-manager.enable = true;
}
