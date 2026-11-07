{ pkgs, ... }:

{
  # packageだけを管理し、~/.config/ghと認証情報には触れない。
  home.packages = with pkgs; [
    gh
    codex
    jujutsu
    wget
    glow
  ];

  programs.bat.enable = true;
  programs.fd.enable = true;

  programs.yazi = {
    enable = true;
    enableZshIntegration = true;
    shellWrapperName = "y";
  };
}
