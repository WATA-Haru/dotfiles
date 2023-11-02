export USER42="hwatahik"
export EMAIL42="hwatahik@student.42tokyo.jp"
export SCHOOL42="42tokyo"	

# Alias definitions.
# You may want to put all your additional aliases into a separate file
# like ~/.bash_aliases, instead of adding them here directly.
# See /usr/share/doc/bash-doc/examples in the bash-doc package.

if [ -d ~/.bash_aliases ]; then
    for filename in `ls -a ~/.bash_aliases`; do
        if [ $filename != "." ] && [ $filename != ".." ]; then
            . ~/.bash_aliases/$filename
        fi
    done
fi

# terminal coloar
case "$TERM" in
    xterm-color|*-256color) color_prompt=yes;;
esac
if [ "$color_prompt" = yes ]; then
    # 色設定あり
    PS1='${debian_chroot:+($debian_chroot)}\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ '
else
    # 端末の256色設定が無効なら色コードは入れない
    PS1='${debian_chroot:+($debian_chroot)}\u@\h:\w\$ '
fi
unset


