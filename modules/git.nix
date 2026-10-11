{ pkgs, ... }:

{
  home.packages = [
    pkgs.ghq
  ];

  programs.git = {
    enable = true;

    includes = [
      {
        path = "~/.config/git/identity";
      }
    ];

    settings = {
      init.defaultBranch = "main";
      ghq.root = "~/ghq";
    };
  };
}
