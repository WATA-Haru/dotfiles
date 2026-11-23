{ nixpkgs, pkgs, ... }:

{
  # packageだけを管理し、~/.config/ghと認証情報には触れない。
  home.packages = with pkgs; [
    gh
    codex
    pi-coding-agent
    jujutsu
    md-tui
    wget
  ];

  nixpkgs.config.allowUnfreePredicate = (
    pkg:
    builtins.elem (pkgs.lib.getName pkg) [
      "claude-code"
      "terraform"
    ]
  );

  programs.bat.enable = true;
  programs.fd.enable = true;

  programs.yazi = {
    enable = true;
    enableZshIntegration = true;
    shellWrapperName = "y";
  };
}
