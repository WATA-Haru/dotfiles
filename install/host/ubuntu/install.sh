#!/usr/bin/env bash
set -euo pipefail

BASE_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
CHECK_DIR="$BASE_DIR/check"
TOOLS_DIR="$BASE_DIR/tools"

run_check() {
  local name="$1"
  local script="$2"

  if [[ ! -f "$script" ]]; then
    echo "  check script not found: $script"
    return 2
  fi

  if bash -e "$script" >/dev/null 2>&1; then
    return 0
  fi
  return 1
}

prompt_yes_no() {
  local prompt="$1"
  local default="${2:-N}"
  local reply=""

  read -r -p "$prompt " reply
  reply="${reply:-$default}"

  case "$reply" in
    [Yy]* ) return 0 ;;
    * ) return 1 ;;
  esac
}

maybe_install() {
  local name="$1"
  local check_script="$2"
  local install_script="$3"

  echo "==> $name"

  local status=0
  if run_check "$name" "$check_script"; then
    status=0
  else
    status=$?
  fi

  if [[ $status -eq 0 ]]; then
    echo "  already installed; skip"
    return 0
  fi

  if [[ $status -eq 2 ]]; then
    echo "  status unknown; check script missing"
  fi

  if prompt_yes_no "  install $name? [y/N]" "N"; then
    if [[ ! -f "$install_script" ]]; then
      echo "  install script not found: $install_script"
      return 1
    fi
    bash "$install_script"
  else
    echo "  skipped"
  fi
}

prompt_chezmoi() {
  local reply=""

  echo "==> chezmoi"
  read -r -p "  apply chezmoi? [y/dry/N] " reply
  case "$reply" in
    [Yy]* )
      bash "$TOOLS_DIR/chezmoi.sh"
      ;;
    [Dd][Rr][Yy]* )
      if command -v chezmoi >/dev/null 2>&1; then
        chezmoi apply --dry-run -v
      else
        echo "  chezmoi not found; skip dry-run"
      fi
      ;;
    * )
      echo "  skipped"
      ;;
  esac
}

# check/package-manager.shで存在チェック
# if 存在する -> skip
# if 存在しない -> 実行する? y/n
maybe_install "package-manager" "$CHECK_DIR/package-manager.sh" "$TOOLS_DIR/package-manager.sh"

# check/base.shで存在チェック
maybe_install "base" "$CHECK_DIR/base.sh" "$TOOLS_DIR/base.sh"

# check/gnome.shで存在チェック
maybe_install "gnome" "$CHECK_DIR/gnome.sh" "$TOOLS_DIR/gnome.sh"

# TODO: gnomeでshutdownする場合は<Ctrl+C>でプロセスを終わらせてくださいのスクリプトを入れたい
echo "shutdown required"

# check/docker.shで存在チェック
maybe_install "docker" "$CHECK_DIR/docker.sh" "$TOOLS_DIR/docker.sh"

# TODO: gnomeでshutdownする場合は<Ctrl+C>でプロセスを終わらせてくださいのスクリプトを入れたい
echo "setup required"
echo "shutdown required"

## check/lc.shで存在チェック
maybe_install "lc" "$CHECK_DIR/lc.sh" "$TOOLS_DIR/lc.sh"
# TODO: gnomeでshutdownする場合は<Ctrl+C>でプロセスを終わらせてくださいのスクリプトを入れたい
echo "shutdown required"

### check/fcitx5.shで存在チェック
maybe_install "fcitx5" "$CHECK_DIR/fcitx5.sh" "$TOOLS_DIR/fcitx5.sh"
# TODO: gnomeでshutdownする場合は<Ctrl+C>でプロセスを終わらせてくださいのスクリプトを入れたい
echo "setup required"
echo "shutdown required"

### check/tools.shで存在チェック
maybe_install "dev-tools" "$CHECK_DIR/tools.sh" "$TOOLS_DIR/dev-tools.sh"

### check/daily-use.shで存在チェック
maybe_install "daily-use" "$CHECK_DIR/daily-use.sh" "$TOOLS_DIR/daily-use-packages.sh"

# run
maybe_install "mise" "$CHECK_DIR/mise.sh" "$TOOLS_DIR/mise.sh"

### chezmoi applyする？もしくはverbose dry-run
# y/dry/n
prompt_chezmoi
