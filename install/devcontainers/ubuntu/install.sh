#!/bin/bash

# sudo command check
if command -v sudo >/dev/null && sudo -n true 2>/dev/null; then
  SUDO="sudo"
else
  SUDO=""
fi

cd $HOME
# ========================
# === package managers ===
# ========================
$SUDO apt update -y
$SUDO apt install -y curl lsb-release wget tmux pkg-config libssl-dev

# =================
# === daily use ===
# =================
$SUDO apt install -y openssl
$SUDO apt install -y libssl-dev
$SUDO apt install -y gawk # for ble.sh
$SUDO apt install -y tig

# ============
# === mise ===
# ============
curl https://mise.run | sh

# ===========
# === fzf ===
# ===========
cd $HOME
## if fzf(mise) is already installed, cleate fzf symlink to mise binary
git clone --depth 1 https://github.com/junegunn/fzf.git $HOME/.fzf
cd $HOME/.fzf && git pull
$HOME/.fzf/install --all

# ======================
# === install ble.sh ===
# ======================
cd $HOME
git clone --recursive --depth 1 --shallow-submodules https://github.com/akinomyoga/ble.sh.git
make -C ble.sh install PREFIX=$HOME/.local
# echo 'source -- ~/.local/share/blesh/ble.sh' >> ~/.bashrc

echo "plese execute post install command"
echo "~/dotfiles/install/devcontainers/ubuntu/post-install.sh"
