#!/bin/bash

sudo apt update

# -- install package managers
sudo apt install curl lsb-release wget
## snap
sudo apt install snapd
## deb-get README: https://github.com/wimpysworld/deb-get
curl -sL https://raw.githubusercontent.com/wimpysworld/deb-get/main/deb-get | sudo -E bash -s install deb-get
## flatpak
sudo apt install flatpak
flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo

# -- install applications
## snap
sudo snap install bitwarden
sudo snap install ghostty --classic

## deb-get
sudo deb-get install obsidian
sudo deb-get install slack-desktop
sudo deb-get install google-chrome-stable

## flatpak
sudo flatpak install flathub net.mkiol.SpeechNote

## other
sudo apt install tmux
sudo apt install gettext # gnome-clipboard building
sudo apt install wl-clipboard # wl-clipboard for nvim

curl -fsS https://dl.brave.com/install.sh | sh

curl -L https://go.microsoft.com/fwlink/?LinkID=760868 -o vscode.deb
sudo apt install ./
rm vscode.deb

# -- applications settings
# vscode neovim initialize
mkdir -p ~/vscode-neovim
touch ~/vscode-neovim/init.lua
mkdir -p ~/Documents/obsidian
