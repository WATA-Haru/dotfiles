function ghq-path() {
  ghq list --full-path | fzf
}

function dev() {
  local moveto
  moveto="$(ghq-path)" || return

  # fzfをEscなどでキャンセルした場合は何もしない。
  [[ -n "$moveto" ]] || return

  cd -- "$moveto" || return

  if [[ -n "$TMUX" ]]; then
    local repo_name="${moveto##*/}"
    tmux rename-session "${repo_name//./-}"
  fi
}

# === appearance prompt ===
# Keep the Ubuntu bash prompt colors and add the current Git branch.
autoload -Uz add-zsh-hook vcs_info
setopt prompt_subst

zstyle ':vcs_info:*' enable git
zstyle ':vcs_info:git:*' formats '%F{yellow}[%b]%f '

function update-git-prompt() {
  vcs_info
}

add-zsh-hook precmd update-git-prompt

PROMPT='%F{green}%n@%m%f:%F{blue}%~%f ${vcs_info_msg_0_}%# '
