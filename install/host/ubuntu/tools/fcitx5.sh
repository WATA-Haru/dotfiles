# cf. /ubuntu/.config/fcitx5/README.md
## fcitx5 packages
sudo apt update
sudo apt -y install language-selector-common
sudo apt -y install $(check-language-support)
sudo apt -y install fcitx5 fcitx5-mozc fcitx5-configtool
im-config -n fcitx5
## fcitx5 Input Method Extension
sudo apt install gnome-browser-connector

## shutdown required
sudo shutdown -r now
echo "shutdown required"
