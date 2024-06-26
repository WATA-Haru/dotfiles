if status is-interactive
    # Commands to run in interactive sessions can go here
end

alias nvim=$HOME/.local/bin/nvim
alias ls='ls --color=auto'
alias la='ls -a'
alias lla='ls -la'
alias rm='rm -i'
alias mv='mv -i'
alias cp='cp -i'
alias c='clear'
alias grep='grep --color=auto'
alias fgrep='fgrep --color=auto'
alias egrep='egrep --color=auto'
alias tmux='tmux -u'

alias gcl='git clone'
alias gs='git status'
alias gcm='git commit -m'
alias gad='git add'
alias gsw='git switch'
alias gbr='git branch'

# 42tokyo setting
alias francinette=$HOME/francinette/tester.sh
alias paco=$HOME/francinette/tester.sh
alias norminette='norminette -R CheckForbiddenSourceHeader'

#- -----------------------------------------------------------------------------
#- asdf
#- -----------------------------------------------------------------------------
# if status is-interactive
#   source ~/.asdf/asdf.fish
# end
source ~/.asdf/asdf.fish

# move often use project folder
alias cdhwata='cd /mnt/c/Users/hwata/OneDrive/ドキュメント/HarutoWatahiki/'
# create symbolic link for pre-installed nvim share and state dir
alias nvimshare='rm -rf ~/.local/share/nvim && mkdir ~/.local/share && ln -s /home/nvim_localplug_cache/share/nvim ~/.local/share/nvim'
alias nvimstate='rm -rf ~/.local/state/nvim && mkdir ~/.local/state && ln -s /home/nvim_localplug_cache/state/nvim ~/.local/state/nvim'
