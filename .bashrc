# ===========================================================================
# funcsions
# ===========================================================================
function activate () {
  local dir="$PWD"

  # .venv を含むディレクトリを上へ辿って探す
  while [ "$dir" != "/" ]; do
    if [ -f "$dir/.venv/bin/activate" ]; then
      source "$dir/.venv/bin/activate"
      return
    fi
    dir=$(dirname "$dir")
  done

  # 見つからなければカレントディレクトリに新しく作成
  uv venv && source .venv/bin/activate && uv pip install isort black pyright
}


function all-cat() {
  local target_dir="$1"
  local EXCLUDE_DIRS=(".venv" "node_modules" "dist" ".git" "__pycache__")
  shift
  local exts=("$@")
  if [[ -z "$target_dir" || "${#exts[@]}" -eq 0 ]]; then
    echo "使い方: all-cat <検索ディレクトリ> <拡張子1> [拡張子2] ..."
    echo "例: all-cat . py js ts"
    return 1
  fi
  # 除外条件を find の -path 条件に変換
  local exclude_args=()
  for dir in "${EXCLUDED_DIRS[@]}"; do
    exclude_args+=(! -path "*/$dir/*")
  done
  # 各拡張子についてファイル検索と出力
  for ext in "${exts[@]}"; do
    find "$target_dir" -type f -name "*.${ext}" "${exclude_args[@]}" | while read -r file; do
      echo "[${file}]"
      echo "\`\`\`${ext}"
      cat "$file"
      echo "\`\`\`"
      echo ""
    done
  done
}

function tree() {
    local dir="$1"
    local prefix="$2"
    local EXCLUDE_DIRS=(".venv" "node_modules" "dist" ".git" "__pycache__")
    is_excluded() {
        local dir_name="$1"
        for exclude in "${EXCLUDE_DIRS[@]}"; do
            if [ "$exclude" = "$dir_name" ]; then
                return 0
            fi
        done
        return 1
    }
    if [ ! -d "$dir" ]; then
        echo "指定したパスがディレクトリではありません: $dir"
        return
    fi
    # ファイル名にスペースが含まれていても安全に処理
    local entries=()
    while IFS= read -r entry; do
        entries+=("$entry")
    done < <(ls -A "$dir")
    local total=${#entries[@]}
    local count=0
    for file in "${entries[@]}"; do
        local fullpath="$dir/$file"
        local connector="├──"
        local new_prefix="${prefix}│   "
        if [ $count -eq $((total - 1)) ]; then
            connector="└──"
            new_prefix="${prefix}    "
        fi
        if is_excluded "$file"; then
            # 除外対象 → 表示のみ（再帰しない）
            if [ -d "$fullpath" ]; then
                echo "${prefix}${connector} $file/"
            else
                echo "${prefix}${connector} $file"
            fi
        else
            if [ -d "$fullpath" ]; then
                echo "${prefix}${connector} $file/"
                tree "$fullpath" "$new_prefix"
            else
                echo "${prefix}${connector} $file"
            fi
        fi
        count=$((count + 1))
    done
}

# ===========================================================================
# aliases
# ===========================================================================
alias vi="nvim"
alias vim="nvim"
alias clip="xsel -bi"
alias open="wsl-open"

# volta
export VOLTA_HOME="$HOME/.volta"
export PATH="$VOLTA_HOME/bin:$PATH"

# neovim
export PATH="$PATH:/opt/nvim-linux-x86_64/bin"

# bun
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"

# uv
export PATH="$HOME/.local/bin/env:$PATH"

# gemini cli
export GEMINI_API_KEY="..."
export GEMINI_MODEL="gemini-2.5-flash"

# qwen coder
export OPENAI_API_KEY="..."
export OPENAI_BASE_URL="https://openrouter.ai/api/v1"
export OPENAI_MODEL="x-ai/grok-code-fast-1"
