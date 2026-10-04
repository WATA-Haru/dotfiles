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
