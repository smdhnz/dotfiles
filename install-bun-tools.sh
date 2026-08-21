#!/usr/bin/env bash
set -euo pipefail

export BUN_INSTALL="$HOME/.bun"
export PATH="$HOME/.local/bin:$BUN_INSTALL/bin:$HOME/.local/share/mise/shims:$PATH"

if ! command -v bun >/dev/null 2>&1; then
	echo "bunが見つかりません。先にmise installを実行してください。" >&2
	exit 1
fi

packages=(
	typescript
	@vtsls/language-server
	@vue/language-server
	@fsouza/prettierd
	@tailwindcss/language-server
	@earendil-works/pi-coding-agent
	@prisma/language-server
	wsl-open
)

bun install --global "${packages[@]}"
mkdir -p "$HOME/.local/bin"
if command -v wsl-open >/dev/null 2>&1; then
	ln -sfn "$(command -v wsl-open)" "$HOME/.local/bin/xdg-open"
fi
