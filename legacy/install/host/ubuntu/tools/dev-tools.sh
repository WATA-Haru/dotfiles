snap install chezmoi --classic
sudo apt install tig

#==================
#=== fzf ===
#==================
# if fzf(mise) is already installed, cleate fzf symlink to mise binary
cd $HOME
git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf
$HOME/.fzf/install


#==================
#=== tmux ===
#==================
sudo apt install tmux


#==================
#=== vscode ===
#==================
cd $HOME
curl -L https://go.microsoft.com/fwlink/?LinkID=760868 -o vscode.deb
sudo apt install ./vscode.deb
rm vscode.deb

#==================
#=== ble.sh ===
#==================
# https://github.com/akinomyoga/ble.sh
# cd ~/
git clone --recursive --depth 1 --shallow-submodules https://github.com/akinomyoga/ble.sh.git
make -C ble.sh install PREFIX=~/.local
echo 'source -- ~/.local/share/blesh/ble.sh' >> ~/.bashrc

#==================
#=== ghostty ===
#==================
sudo snap install ghostty --classic

