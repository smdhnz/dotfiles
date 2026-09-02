# Python virtual environment activator (using uv)
activate() {
	local dir="$PWD"
	while [ "$dir" != "/" ]; do
		if [ -f "$dir/.venv/bin/activate" ]; then
			source "$dir/.venv/bin/activate"
			unset PYTHONPATH
			return
		fi
		dir=$(dirname "$dir")
	done

	if ! command -v uv >/dev/null 2>&1; then
		echo "❌ uv is not installed. Cannot create venv."
		return 1
	fi

	echo "==> Creating new venv with uv..."
	uv venv && source .venv/bin/activate && unset PYTHONPATH && uv pip install ruff pyright
}

# Simple directory tree view
tree() {
	local OPTIND=1
	local exclude_dots=false
	local exclude_underscore=false
	local dirs_only=false

	while getopts "duf" opt; do
		case "$opt" in
		d) exclude_dots=true ;;
		u) exclude_underscore=true ;;
		f) dirs_only=true ;;
		esac
	done
	shift $((OPTIND - 1))

	local target_dir="${1:-.}"
	local exclude_dirs=("node_modules" "dist" "build" ".venv" "__pycache__" ".git")

	is_excluded() {
		local name="$1"
		for exclude in "${exclude_dirs[@]}"; do
			if [[ "$name" == "$exclude" ]]; then return 0; fi
		done
		return 1
	}

	generate_tree() {
		local dir="$1"
		local prefix="$2"
		local entries=()
		local find_opts=()

		$exclude_dots && find_opts+=(! -name ".*")
		$exclude_underscore && find_opts+=(! -name "_*")
		$dirs_only && find_opts+=(-type d)

		while IFS= read -r -d $'\0' entry; do
			entries+=("$entry")
		done < <(find "$dir" -mindepth 1 -maxdepth 1 "${find_opts[@]}" -print0 | sort -z)

		local count=${#entries[@]}
		for i in "${!entries[@]}"; do
			local path="${entries[$i]}"
			local name
			name=$(basename "$path")
			local connector="├──"
			local new_prefix="$prefix│   "

			if [ "$i" -eq "$((count - 1))" ]; then
				connector="└──"
				new_prefix="$prefix    "
			fi

			if [ -d "$path" ]; then
				echo "${prefix}${connector} ${name}/"
				if ! is_excluded "$name"; then
					generate_tree "$path" "$new_prefix"
				fi
			else
				echo "${prefix}${connector} ${name}"
			fi
		done
	}

	echo "$(basename "$target_dir")/"
	generate_tree "$target_dir" ""
}

# Concatenate files with markdown formatting
xcat() {
	local exclude_dirs=(".venv" "node_modules" "dist" ".git" "__pycache__" "test" ".DS_Store" ".idea" ".vscode")
	local target_paths=()
	local extensions=""

	while [[ $# -gt 0 ]]; do
		case "$1" in
		--exp)
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
		echo "Usage: xcat <path1> [path2...] [--exp <ext1,ext2...>]"
		return 1
	fi

	print_formatted() {
		local file="$1"
		echo "[$file]"
		local ext="${file##*.}"
		[[ "$file" == "$ext" ]] && ext=""
		echo '```'"$ext"
		cat "$file"
		echo '```'
		echo ""
	}

	local find_opts=()
	for dir in "${exclude_dirs[@]}"; do
		find_opts+=(! -path "*/$dir/*")
	done

	if [[ -n "$extensions" ]]; then
		local ext_args=()
		ext_args+=(\()
		IFS=',' read -ra ADDR <<<"$extensions"
		local is_first=true
		for ext in "${ADDR[@]}"; do
			if [ "$is_first" = true ]; then is_first=false; else ext_args+=(-o); fi
			ext_args+=(-name "*.$ext")
		done
		ext_args+=(\))
		find_opts+=("${ext_args[@]}")
	fi

	find "${target_paths[@]}" -type f "${find_opts[@]}" 2>/dev/null | while read -r file; do
		print_formatted "$file"
	done
}

# Fix file and directory permissions
fixperm() {
	local target="${1:-.}"
	local exclude_dirs=(".venv" ".git")
	local find_cmd=("find" "$target")

	for dir in "${exclude_dirs[@]}"; do
		find_cmd+=(-path "*/$dir" -prune -o)
	done

	# Correctly build the find command to apply chmod
	"${find_cmd[@]}" -type d -exec chmod 755 {} +
	"${find_cmd[@]}" -type f -exec chmod 644 {} +
}

# Move files to a daily trash directory
del() {
	local trash_root="${DEVBOX_HOME:-$HOME}/.deleted"
	local today
	today=$(date +%Y-%m-%d)
	local trash_dir="$trash_root/$today"

	mkdir -p "$trash_dir"

	# Clean up old trash (older than 7 days)
	if [ -d "$trash_root" ]; then
		find "$trash_root" -maxdepth 1 -type d -mtime +7 -exec chmod -R u+rw {} + 2>/dev/null
		find "$trash_root" -maxdepth 1 -type d -mtime +7 -exec rm -rf {} + 2>/dev/null
	fi

	if [ $# -eq 0 ]; then
		echo "Usage: del <file_or_dir> ..."
		return 1
	fi

	for item in "$@"; do
		[[ "$item" == -* ]] && continue
		if [ -e "$item" ]; then
			local base_name
			base_name=$(basename "$item")
			local dest="$trash_dir/$base_name"
			if [ -e "$dest" ]; then
				dest="${dest}_$(date +%H%M%S)"
			fi
			chmod -R u+rw "$item" 2>/dev/null
			if mv "$item" "$dest" 2>/dev/null; then
				echo "Moved to trash: $item"
			else
				echo "del: $item: Permission denied (try sudo)"
			fi
		else
			echo "del: $item: No such file or directory"
		fi
	done
}

# Send message or file to Discord via Webhook
# Requires DISCORD_WEBHOOK_URL to be set in .env or the environment.
discord() {
	local webhook_url="${DISCORD_WEBHOOK_URL:-}"

	if [ -z "$webhook_url" ]; then
		echo "❌ DISCORD_WEBHOOK_URL is not set."
		return 1
	fi

	if ! command -v curl >/dev/null 2>&1 || ! command -v jq >/dev/null 2>&1; then
		echo "❌ curl and jq are required."
		return 1
	fi

	# Handle pipe input
	if [ ! -t 0 ]; then
		local content
		content=$(cat)
		local escaped
		escaped=$(printf '%s' "$content" | jq -Rs .)
		curl -s -H "Content-Type: application/json" -X POST -d "{\"content\": $escaped}" "$webhook_url" >/dev/null
		return
	fi

	# Handle file upload
	if [ "$1" = "-f" ]; then
		local file="$2"
		if [ ! -f "$file" ]; then
			echo "❌ File not found: $file"
			return 1
		fi

		if [ "$3" = "-e" ]; then
			if ! command -v gpg >/dev/null 2>&1; then
				echo "❌ gpg is required."
				return 1
			fi
			local passphrase="$4"
			local enc_file="${file}.gpg"
			gpg --batch --yes --quiet --passphrase "$passphrase" -c "$file"
			curl -s -X POST -F "file=@${enc_file}" "$webhook_url" >/dev/null
			rm -f "$enc_file"
		else
			curl -s -X POST -F "file=@${file}" "$webhook_url" >/dev/null
		fi
		return
	fi

	# Handle text message
	if [ $# -eq 0 ]; then
		echo "Usage: discord <message> | discord -f <file> [-e <passphrase>] | echo 'msg' | discord"
		return 1
	fi

	local content="$*"
	local escaped
	escaped=$(printf '%s' "$content" | jq -Rs .)
	curl -s -H "Content-Type: application/json" -X POST -d "{\"content\": $escaped}" "$webhook_url" >/dev/null
}

# Copy to clipboard via OSC 52
clip() {
	local input
	if [ -t 0 ]; then
		input="$*"
	else
		input=$(cat)
	fi
	[ -z "$input" ] && return
	printf "\033]52;c;$(printf "%s" "$input" | base64 | tr -d '\n')\a"
}

# Extract various archive formats
extract() {
	if [ $# -eq 0 ]; then
		echo "Usage: extract <archive>"
		return 1
	fi

	if [ ! -f "$1" ]; then
		echo "❌ File not found: $1"
		return 1
	fi

	case "$1" in
	*.tar.bz2 | *.tbz2) tar xjf "$1" ;;
	*.tar.gz | *.tgz) tar xzf "$1" ;;
	*.tar.xz | *.txz) tar xJf "$1" ;;
	*.tar) tar xf "$1" ;;
	*.zip) unzip "$1" ;;
	*.gz) gunzip "$1" ;;
	*.bz2) bunzip2 "$1" ;;
	*.xz) unxz "$1" ;;
	*)
		echo "❌ Unsupported archive: $1"
		return 1
		;;
	esac
}

# Show listening ports
ports() {
	if command -v lsof >/dev/null 2>&1; then
		lsof -i -P -n | grep LISTEN
	elif command -v ss >/dev/null 2>&1; then
		ss -ltnp
	elif command -v netstat >/dev/null 2>&1; then
		netstat -ltnp
	else
		echo "❌ lsof, ss, or netstat is required."
		return 1
	fi
}

# Serve current directory over HTTP
serve() {
	local port="${1:-8000}"

	if command -v python3 >/dev/null 2>&1; then
		python3 -m http.server "$port"
	elif command -v python >/dev/null 2>&1; then
		python -m SimpleHTTPServer "$port"
	else
		echo "❌ python3 or python is required."
		return 1
	fi
}

# Undo the last git commit while keeping changes staged
gundo() {
	if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
		echo "❌ Not in a git repository"
		return 1
	fi

	git reset --soft HEAD~1
}
