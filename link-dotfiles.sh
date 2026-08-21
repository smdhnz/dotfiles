#!/usr/bin/env bash
set -euo pipefail

repo_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
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
