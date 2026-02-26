DOTFILES_REPO="https://github.com/WATA-Haru/dotfiles.git"

# ===============
# === chezmoi ===
# ===============
# INFO: snap cannot use in docker container
sh -c "$(curl -fsLS get.chezmoi.io)" -- -b $HOME/.local/bin

# `PromptString` requires interactive operation
chezmoi init $DOTFILES_REPO
chezmoi apply

# =====================
# === install tools ===
# =====================
mise install
mise use

