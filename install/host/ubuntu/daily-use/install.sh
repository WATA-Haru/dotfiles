#!/bin/bash

# install applications
## snap
sudo snap install bitwarden

## deb-get
sudo deb-get install slack-desktop
sudo deb-get install google-chrome-stable

## flatpak
sudo flatpak install flathub net.mkiol.SpeechNote

## brave
curl -fsS https://dl.brave.com/install.sh | sh


## openssl
sudo apt install openssl
sudo apt install libssl-dev
sudo apt install gawk # for ble.sh
sudo apt install tig
sudo snap install yazi --classic

