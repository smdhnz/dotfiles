# shellcheck shell=bash
# This file is sourced from ~/.bashrc. Keep it fast and side-effect free.

export EDITOR=nvim
export COLORTERM=truecolor
export BUN_INSTALL="$HOME/.bun"
export PATH="$HOME/.local/bin:$BUN_INSTALL/bin:$HOME/.local/share/mise/shims:$PATH"

if [[ $- == *i* ]] && command -v mise >/dev/null 2>&1; then
	eval "$(mise activate bash)"
fi

DOTFILES_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
if [ -f "$DOTFILES_DIR/.env" ]; then
	set -a
	# shellcheck disable=SC1091
	source "$DOTFILES_DIR/.env"
	set +a
fi

alias vi="nvim"
alias vim="nvim"
alias pip="uv pip"
alias rm='del'
alias lg="lazygit"
alias ld="lazydocker"
alias open="wsl-open"
alias time-sync="sudo hwclock -s"
if command -v fdfind >/dev/null 2>&1 && ! command -v fd >/dev/null 2>&1; then
	alias fd="fdfind"
fi

# shellcheck disable=SC1091
source "$DOTFILES_DIR/shell_functions.sh"

if command -v wsl-open >/dev/null 2>&1; then
	export BROWSER=wsl-open
	export GH_BROWSER=wsl-open
fi

unset DOTFILES_DIR
