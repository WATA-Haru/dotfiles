#========================
#=== gnome tools install ===
#========================
sudo apt install gettext # gnome-clipboard building
sudo apt install wl-clipboard # wl-clipboard for nvim

#=============================
#======== gnome extension cli Manually =========
#=============================
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


#=============================
#======== gnome extension dock settings Manually =========
#=============================
# cf. https://namileriblog.com/linux/first-setting-ubuntu_2404/#i-20
# cf. https://gihyo.jp/admin/serial/01/ubuntu-recipe/0541
# cf. https://www.reddit.com/r/Ubuntu/comments/hfd8nv/mount_a_drive_but_prevent_it_from_showing_on_the/?tl=ja

# gnomeのuser拡張を有効化
gsettings set org.gnome.shell disable-user-extensions false

# Dockの常時表示を無効化
gsettings set org.gnome.shell.extensions.dash-to-dock dock-fixed false

# Dockをウィンドウの状態に関係なく常に隠す
gsettings set org.gnome.shell.extensions.dash-to-dock intellihide false

# マウスカーソルを左端にあわせるだけでDock表示
gsettings set org.gnome.shell.extensions.dash-to-dock require-pressure-to-show false

# Dockのサイズはアイコン表示に必要な分だけにする
gsettings set org.gnome.shell.extensions.dash-to-dock extend-height false

# Dockのサイズは最大でも画面サイズの半分
gsettings set org.gnome.shell.extensions.dash-to-dock height-fraction 0.5

# Dockのサイズを超えるアイコンを表示する際は、アイコンを小さくする
gsettings set org.gnome.shell.extensions.dash-to-dock icon-size-fixed true

# Dockを画面の上端に表示する
gsettings set org.gnome.shell.extensions.dash-to-dock dock-position 'LEFT'

# Dockにmountしたssdを表示しない
gsettings set org.gnome.shell.extensions.dash-to-dock show-mounts 'false'

# バッテリーの残量のパーセンテージを表示
gsettings set org.gnome.desktop.interface show-battery-percentage true

# caps to ctrl
gsettings set org.gnome.desktop.input-sources xkb-options "['ctrl:nocaps']"

# https://askubuntu.com/questions/1335398/ubuntu-21-04-remove-trash-user-and-drive-icon-from-desktop
gsettings set org.gnome.shell.extensions.ding show-home false
gsettings set org.gnome.shell.extensions.ding show-trash false
