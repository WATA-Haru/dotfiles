#!/bin/bash
sudo apt update

# install package managers
sudo apt install curl lsb-release wget

## snap
sudo apt install snapd

## deb-get README: https://github.com/wimpysworld/deb-get
curl -sL https://raw.githubusercontent.com/wimpysworld/deb-get/main/deb-get | sudo -E bash -s install deb-get

## flatpak
sudo apt install flatpak
flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo

