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

if [ ! -x "$HOME/.local/bin/mise" ]; then
	curl https://mise.run | sh
fi
export PATH="$HOME/.local/bin:$HOME/.local/share/mise/shims:$PATH"
hash -r

mise trust "$repo_dir/mise.toml"
mise --cd "$repo_dir" install
mise reshim

"$repo_dir/link-dotfiles.sh"
"$repo_dir/install-bun-tools.sh"

echo "インストール完了。新しいbashで動作確認してください。"
