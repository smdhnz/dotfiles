#!/usr/bin/env bash
set -euo pipefail

repo_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"

link_file() {
	local source=$1
	local target=$2
	mkdir -p "$(dirname -- "$target")"
	if [ -d "$target" ] && [ ! -L "$target" ]; then
		printf 'error: ディレクトリは置換できません: %s\n' "$target" >&2
		return 1
	fi
	if [ -e "$target" ] && [ ! -L "$target" ]; then
		rm -f "$target"
		printf 'replace: %s\n' "$target"
	fi
	ln -sfn "$source" "$target"
	printf 'link: %s -> %s\n' "$target" "$source"
}

link_file "$repo_dir/mise.toml" "$HOME/.config/mise/config.toml"
link_file "$repo_dir/.config/nvim/init.lua" "$HOME/.config/nvim/init.lua"
link_file "$repo_dir/.pi/agent/AGENTS.md" "$HOME/.pi/agent/AGENTS.md"
link_file "$repo_dir/.pi/agent/mcp.json" "$HOME/.pi/agent/mcp.json"
link_file "$repo_dir/.pi/agent/extensions" "$HOME/.pi/agent/extensions"

settings_dir="$HOME/.pi/agent"
settings_file="$settings_dir/settings.json"
settings_tmp=$(mktemp "$settings_dir/settings.json.XXXXXX")
trap 'rm -f "$settings_tmp"' EXIT
if [ -f "$settings_file" ]; then
	jq -s '.[0] * .[1]' "$settings_file" "$repo_dir/.pi/agent/settings.json" >"$settings_tmp"
else
	jq '.' "$repo_dir/.pi/agent/settings.json" >"$settings_tmp"
fi
chmod 600 "$settings_tmp"
mv "$settings_tmp" "$settings_file"
trap - EXIT
printf 'update: %s (merge %s)\n' "$settings_file" "$repo_dir/.pi/agent/settings.json"

marker_start='# >>> dotfiles >>>'
marker_end='# <<< dotfiles <<<'
tmp_file=$(mktemp)
trap 'rm -f "$tmp_file"' EXIT

awk -v start="$marker_start" -v end="$marker_end" '
	$0 == start { managed = 1; next }
	$0 == end { managed = 0; next }
	managed { next }
	$0 == "" { blanks = blanks "\n"; next }
	{ printf "%s", blanks; blanks = ""; print }
' "$HOME/.bashrc" >"$tmp_file"

cat >>"$tmp_file" <<EOF

$marker_start
source "$repo_dir/shell_setup.sh"
$marker_end
EOF
mv "$tmp_file" "$HOME/.bashrc"
trap - EXIT
printf 'update: %s (source %s)\n' "$HOME/.bashrc" "$repo_dir/shell_setup.sh"
