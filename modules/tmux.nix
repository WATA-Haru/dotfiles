{ ... }:

{
  programs.tmux = {
    enable = true;

    terminal = "tmux-256color";
    baseIndex = 1;
    keyMode = "vi";
    mouse = true;
    prefix = "C-f";
    escapeTime = 0;
    focusEvents = true;

    customPaneNavigationAndResize = true;
    resizeAmount = 5;

    # Keep the conventional /tmp/tmux-UID socket during this migration.
    secureSocket = false;

    extraConfig = builtins.readFile ../dot_config/tmux/tmux.conf;
  };
}

