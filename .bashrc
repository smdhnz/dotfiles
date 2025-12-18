

# ===========================================================================
# funcsions
# ===========================================================================
br-sync() {
  if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    echo "⚠️  Not inside a Git repository. Skipping git_force_sync."
    return 1
  fi

  if [ -z "$1" ]; then
    # 引数なし → 現在のブランチを同期するモード
    local branch_name
    branch_name=$(git rev-parse --abbrev-ref HEAD)

    echo "==> Forcing current branch '$branch_name' to match origin/$branch_name"
    git stash push -m "WIP: 変更一時退避"
    git fetch origin
    git reset --hard origin/"$branch_name"
    git stash pop
  else
    # 引数あり → 指定ブランチを `branch -f` で強制同期するモード
    local target_branch="$1"

    echo "==> Forcing branch '$target_branch' to match origin/$target_branch"
    git fetch origin
    git branch -f "$target_branch" origin/"$target_branch"
  fi
}

function activate () {
  local dir="$PWD"
  while [ "$dir" != "/" ]; do
    if [ -f "$dir/.venv/bin/activate" ]; then
      source "$dir/.venv/bin/activate"
      return
    fi
    dir=$(dirname "$dir")
  done
  uv venv && source .venv/bin/activate && uv pip install isort black pyright
}

function tree() {
    local TARGET_DIR="${1:-.}"
    local EXCLUDE_DIRS=("node_modules" "dist" "build" ".venv" "__pycache__")
    is_excluded() {
        local name="$1"
        for exclude in "${EXCLUDE_DIRS[@]}"; do
            if [[ "$name" == "$exclude" ]]; then
                return 0  # true
            fi
        done
        return 1  # false
    }
    generate_tree() {
        local DIR=$1
        local PREFIX=$2
        local entries=()
        while IFS= read -r -d $'\0' entry; do
            entries+=("$entry")
        done < <(find "$DIR" -mindepth 1 -maxdepth 1 ! -name ".*" -print0 | sort -z)
        local count=${#entries[@]}
        for i in "${!entries[@]}"; do
            local path="${entries[$i]}"
            local name=$(basename "$path")
            local connector="├──"
            local new_prefix="$PREFIX│   "

            if [ "$i" -eq "$((count - 1))" ]; then
                connector="└──"
                new_prefix="$PREFIX    "
            fi

            if [ -d "$path" ]; then
                echo "${PREFIX}${connector} ${name}/"
                if ! is_excluded "$name"; then
                    generate_tree "$path" "$new_prefix"
                fi
            else
                echo "${PREFIX}${connector} ${name}"
            fi
        done
    }
    echo "$(basename "$TARGET_DIR")/"
    generate_tree "$TARGET_DIR" ""
}

function xcat() {
  # ==============================================================================
  # [使い方]
  #   xcat <パス1> [パス2...] [--exp <拡張子1,拡張子2...>]
  #
  # [例]
  #   1. 特定の拡張子のみ:  xcat src/ --exp py,js
  #   2. ディレクトリ全体:  xcat .
  #   3. 特定ファイル指定:  xcat README.md ./config/
  #
  # [特徴]
  #   - ファイル名をヘッダーに、中身をMarkdownコードブロック (```) で出力します。
  #   - node_modules, .git, .venv などの不要フォルダは自動的に除外されます。
  # ==============================================================================
  local EXCLUDE_DIRS=(".venv" "node_modules" "dist" ".git" "__pycache__" "test" ".DS_Store" ".idea" ".vscode")

  local target_paths=()
  local extensions=""

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --exp)
        if [[ -z "$2" || "$2" == -* ]]; then
          echo "エラー: --exp の後には拡張子を指定してください (例: py,js)"
          return 1
        fi
        extensions="$2"
        shift 2
        ;;
      *)
        target_paths+=("$1")
        shift
        ;;
    esac
  done

  if [[ ${#target_paths[@]} -eq 0 ]]; then
    echo "Usage: xcat <パス1> [パス2...] [--exp <拡張子1,拡張子2...>]"
    echo "  例1: xcat functions/* --exp py"
    return 1
  fi

  print_formatted() {
    local file="$1"
    echo "[${file}]"
    local ext="${file##*.}"
    if [[ "$file" == "$ext" ]]; then ext=""; fi
    echo "\`\`\`${ext}"
    cat "$file"
    echo "\`\`\`"
    echo ""
  }

local find_opts=()

for dir in "${EXCLUDE_DIRS[@]}"; do
  find_opts+=(! -path "*/$dir/*")
done

if [[ -n "$extensions" ]]; then
  local ext_args=()
  ext_args+=(\() # 括弧開始

  IFS=',' read -ra ADDR <<< "$extensions"
  local is_first=true

  for ext in "${ADDR[@]}"; do
    if [ "$is_first" = true ]; then
      is_first=false
    else
      ext_args+=(-o)
    fi
    ext_args+=(-name "*.${ext}")
  done

  ext_args+=(\)) # 括弧終了
  find_opts+=("${ext_args[@]}")
fi

find "${target_paths[@]}" -type f "${find_opts[@]}" | while read -r file; do
print_formatted "$file"
done
unset -f print_formatted
}

function fixperms() {
  local TARGET="${1:-.}"
  local EXCLUDE_DIRS=( ".venv" )
  local -a PRUNE_EXPR=()
  if ((${#EXCLUDE_DIRS[@]} > 0)); then
    PRUNE_EXPR+=( \( )
    for dir in "${EXCLUDE_DIRS[@]}"; do
      local d="${dir%/}"
      PRUNE_EXPR+=( -path "$TARGET/$d" -o -path "$TARGET/$d/*" -o )
    done
    unset 'PRUNE_EXPR[${#PRUNE_EXPR[@]}-1]'
    PRUNE_EXPR+=( \) -prune -o )
  fi
  echo "[fixperms] target: $TARGET"
  echo "[fixperms] excludes: ${EXCLUDE_DIRS[*]:-(none)}"
  # ディレクトリを 755
  if ((${#PRUNE_EXPR[@]})); then
    find "$TARGET" "${PRUNE_EXPR[@]}" -type d -exec chmod 755 {} +
  else
    find "$TARGET" -type d -exec chmod 755 {} +
  fi
  # ファイルを 644
  if ((${#PRUNE_EXPR[@]})); then
    find "$TARGET" "${PRUNE_EXPR[@]}" -type f -exec chmod 644 {} +
  else
    find "$TARGET" -type f -exec chmod 644 {} +
  fi
}

discord() {
  # ==============================================================================
  # [使い方]
  #   1. メッセージ送信: discord "メッセージ内容"
  #   2. パイプ/ログ送信: echo "エラー発生" | discord
  #   3. ファイル送信:   discord -f <ファイルパス>
  #   4. 暗号化して送信: discord -f <ファイルパス> -e "<パスフレーズ>"
  #
  # [必須コマンド]
  #   curl, jq, gpg
  # ==============================================================================
  local WEBHOOK_URL="https://discord.com/api/webhooks/1430739694852898838/WoI7GIB7uM3PWTyN4FqPiBsHby_B-0RSwDRODq14Uds7FPOtJFcmW5NInOxsjVwowh8Q"
  if [ ! -t 0 ]; then
    CONTENT=$(cat)
    ESCAPED=$(printf '%s' "$CONTENT" | jq -Rs .)
    curl -s -H "Content-Type: application/json" \
      -X POST \
      -d "{\"content\": $ESCAPED}" \
      "${WEBHOOK_URL}"
    echo
    return
  fi
  if [ "$1" = "-f" ]; then
    FILE="$2"
    if [ "$3" = "-e" ]; then
      PASSPHRASE="$4"
      ENC_FILE="${FILE}.gpg"
      gpg --batch --yes --quiet --passphrase "$PASSPHRASE" -c "$FILE"
      curl -s -X POST \
        -F "file=@${ENC_FILE}" \
        "${WEBHOOK_URL}" | jq
      rm -f "$ENC_FILE"
    else
      curl -s -X POST \
        -F "file=@${FILE}" \
        "${WEBHOOK_URL}" | jq
    fi
    return
  fi
  CONTENT="$*"
  ESCAPED=$(printf '%s' "$CONTENT" | jq -Rs .)
  curl -s -H "Content-Type: application/json" \
    -X POST \
    -d "{\"content\": $ESCAPED}" \
    "${WEBHOOK_URL}"
  echo
}


# ===========================================================================
# aliases
# ===========================================================================
alias vi="nvim"
alias vim="nvim"
alias clip="xsel -bi"
alias open="wsl-open"
alias pip="uv pip"


# ===========================================================================
# exports
# ===========================================================================
export VOLTA_HOME="$HOME/.volta"
export PATH="$VOLTA_HOME/bin:$PATH"
export PATH="$PATH:/opt/nvim-linux-x86_64/bin"
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"
export PATH="$HOME/.local/bin/env:$PATH"
