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

