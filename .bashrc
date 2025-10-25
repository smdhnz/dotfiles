

# ===========================================================================
# funcsions
# ===========================================================================
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
  local exclude_args=()
  for dir in "${EXCLUDED_DIRS[@]}"; do
    exclude_args+=(! -path "*/$dir/*")
  done
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

# qwen coder
export OPENAI_API_KEY="..."
export OPENAI_BASE_URL="https://openrouter.ai/api/v1"
export OPENAI_MODEL="x-ai/grok-code-fast-1"
