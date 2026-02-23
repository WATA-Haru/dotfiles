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
$SUDO apt update
$SUDO apt install curl lsb-release wget
$SUDO apt install snapd

# =================
# === daily use ===
# =================
$SUDO apt install openssl
$SUDO apt install libssl-dev
$SUDO apt install gawk # for ble.sh
$SUDO apt install tig
$SUDO snap install yazi --classic

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
cd $HOME/.fzf && git pull && ./install
$HOME/.fzf/install

# ======================
# === install ble.sh ===
# ======================
cd $HOME
git clone --recursive --depth 1 --shallow-submodules https://github.com/akinomyoga/ble.sh.git
make -C ble.sh install PREFIX=$HOME/.local
# echo 'source -- ~/.local/share/blesh/ble.sh' >> ~/.bashrc

# =====================
# === install tools ===
# =====================
mise install
mise use

# ===============
# === chezmoi ===
# ===============
chezmoi init
chezmoi apply
