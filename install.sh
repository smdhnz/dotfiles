#!/usr/bin/env bash
set -euo pipefail

repo_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"

if [ "$(id -u)" -eq 0 ]; then
	echo "rootではなく通常ユーザーで実行してください。" >&2
	exit 1
fi

if ! grep -q '^ID=ubuntu' /etc/os-release; then
	echo "このスクリプトはUbuntu専用です。" >&2
	exit 1
fi

mapfile -t apt_packages < <(grep -Ev '^\s*(#|$)' "$repo_dir/packages.apt")
sudo apt-get update
sudo apt-get install -y "${apt_packages[@]}"

if ! command -v mise >/dev/null 2>&1 || [[ "$(command -v mise)" == /nix/store/* ]]; then
	curl https://mise.run | sh
fi
export PATH="$HOME/.local/bin:$HOME/.local/share/mise/shims:$PATH"

mise trust "$repo_dir/mise.toml"
mise --cd "$repo_dir" install
mise reshim

mkdir -p "$HOME/.config/nvim" "$HOME/.pi/agent"
ln -sfn "$repo_dir/.config/nvim/init.lua" "$HOME/.config/nvim/init.lua"
ln -sfn "$repo_dir/.pi/agent/AGENTS.md" "$HOME/.pi/agent/AGENTS.md"
ln -sfn "$repo_dir/.pi/agent/mcp.json" "$HOME/.pi/agent/mcp.json"

marker_start='# >>> dotfiles >>>'
marker_end='# <<< dotfiles <<<'
if ! grep -Fq "$marker_start" "$HOME/.bashrc"; then
	cat >>"$HOME/.bashrc" <<EOF

$marker_start
source "$repo_dir/shell_setup.sh"
$marker_end
EOF
fi

"$repo_dir/install-bun-tools.sh"

echo "インストール完了。新しいbashで動作確認してください。"
