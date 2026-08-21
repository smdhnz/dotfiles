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
