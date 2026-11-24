{ nixpkgs, pkgs, ... }:

{
  nixpkgs.config.allowUnfreePredicate = (
    pkg:
    builtins.elem (pkgs.lib.getName pkg) [
      "claude-code"
      "terraform"
    ]
  );

  home.packages = with pkgs; [
    gh
    codex
    pi-coding-agent
    jujutsu
    md-tui
    wget

    # unfree
    claude-code
    terraform
  ];

  programs.bat.enable = true;
  programs.fd.enable = true;

  programs.yazi = {
    enable = true;
    enableZshIntegration = true;
    shellWrapperName = "y";
  };
}
