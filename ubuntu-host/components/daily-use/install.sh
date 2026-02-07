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

