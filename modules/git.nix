{ ... }:

{
  programs.git = {
    enable = true;

    includes = [
      {
        path = "~/.config/git/identity";
      }
    ];
  };

  programs.git.settings = {
    init.defaultBranch = "main";
  };
}
