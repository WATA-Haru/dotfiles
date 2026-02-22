#!bin/bash
LANG=C LC_ALL=C xdg-user-dirs-gtk-update

echo "shutdown required"
// TODO: if statement
sudo shutdown -r now
