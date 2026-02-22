#!/bin/bash

# gnome-extensions-cli:  https://github.com/essembeh/gnome-extensions-cli
# kimpanelはinstallとenableできるが`extension-manager`で有効化ができないためGUIで別途設定
# gnome-extensions-cli install kimpanel@kde.org

# tiling-assistant https://github.com/Leleat/Tiling-Assistant/wiki/Active-Window-Hint
gext install tiling-assistant@leleat-on-github
gext enable tiling-assistant@leleat-on-github

# clipboard-history
cd ~/.local/share/gnome-shell/extensions/ && \
  git clone https://github.com/SUPERCILEX/gnome-clipboard-history.git clipboard-history@alexsaveau.dev && \
  cd clipboard-history@alexsaveau.dev && \
  make
gnome-extensions enable clipboard-history@alexsaveau.dev
