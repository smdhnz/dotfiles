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

# Show Pi token usage and cost for the past N days/months (default: 7 days, in JST)
piusage() {
	if ! command -v python3 >/dev/null 2>&1; then
		echo "❌ python3 is required for pi-usage."
		return 1
	fi

	python3 - "$@" <<'EOF'
import glob, json, os, sys, unicodedata, argparse, csv
from datetime import datetime, timedelta, timezone

def display_width(text):
    w = 0
    for ch in text:
        if unicodedata.east_asian_width(ch) in ('F', 'W'):
            w += 2
        else:
            w += 1
    return w

def pad_right(text, width):
    w = display_width(text)
    return text + ' ' * max(0, width - w)

parser = argparse.ArgumentParser(add_help=False)
parser.add_argument("days_pos", nargs="?", type=int, default=None)
parser.add_argument("-d", "--days", type=int, default=None)
parser.add_argument("-m", "--months", type=int, default=None)
parser.add_argument("-p", "--provider", action="append", default=[])
parser.add_argument("--today", action="store_true")
parser.add_argument("--csv", action="store_true")
parser.add_argument("-h", "--help", action="store_true")

try:
    args = parser.parse_args()
except Exception:
    args = parser.parse_args(["-h"])

if args.help:
    print("使い方: pi-usage [日数] [オプション]")
    print("")
    print("オプション:")
    print("  [数値]               集計対象の日数 (デフォルト: 7)")
    print("  -d, --days <N>       集計対象の日数")
    print("  -m, --months <N>     集計対象の月数 (1か月 = 30日)")
    print("  -p, --provider <P>   プロバイダ名で絞り込み (複数指定・カンマ区切り可)")
    print("  --today              今日の利用分のみ表示")
    print("  --csv                CSV形式で標準出力に出力")
    print("  -h, --help           このヘルプを表示")
    sys.exit(0)

days = 7
if args.today:
    days = 1
elif args.months is not None:
    days = args.months * 30
elif args.days is not None:
    days = args.days
elif args.days_pos is not None:
    days = args.days_pos
days = max(1, days)

filter_providers = []
for p_arg in args.provider:
    for p in p_arg.split(","):
        p = p.strip().lower()
        if p:
            filter_providers.append(p)

jst = timezone(timedelta(hours=9))
now = datetime.now(jst)
start_date = (now - timedelta(days=days-1)).replace(hour=0, minute=0, second=0, microsecond=0)

sessions_dir = os.environ.get("PI_SESSIONS_DIR") or os.path.expanduser("~/.pi/agent/sessions")
files = glob.glob(f"{sessions_dir}/**/*.jsonl", recursive=True)

if not files:
    if args.csv:
        print("date,calls,input_tokens,output_tokens,cache_read,cache_write,total_tokens,cost_usd")
    else:
        print(f"No session files found in {sessions_dir}")
    sys.exit(0)

weekday_names = ["月", "火", "水", "木", "金", "土", "日"]
daily = {}
models = {}
totals = {"input": 0, "output": 0, "cache_r": 0, "cache_w": 0, "total": 0, "cost": 0.0, "calls": 0}

for i in range(days):
    d_dt = (now - timedelta(days=days-1-i))
    d_key = d_dt.strftime("%Y-%m-%d")
    w_idx = d_dt.weekday()
    w_name = weekday_names[w_idx]
    daily[d_key] = {
        "label": f"{d_key} ({w_name})",
        "date": d_key,
        "weekday": w_idx,
        "input": 0,
        "output": 0,
        "cache_r": 0,
        "cache_w": 0,
        "total": 0,
        "cost": 0.0,
        "calls": 0
    }

for f in files:
    try:
        with open(f, "r", encoding="utf-8", errors="ignore") as fp:
            for line in fp:
                if not line.strip(): continue
                data = json.loads(line)
                if data.get("type") == "message" and "message" in data:
                    msg = data["message"]
                    if isinstance(msg, dict) and msg.get("usage"):
                        provider = str(msg.get("provider") or "unknown")
                        if filter_providers:
                            prov_lower = provider.lower()
                            if not any(fp in prov_lower for fp in filter_providers):
                                continue

                        ts_str = data.get("timestamp") or msg.get("timestamp")
                        if not ts_str: continue
                        try:
                            if isinstance(ts_str, (int, float)):
                                dt = datetime.fromtimestamp(ts_str / 1000.0, tz=jst)
                            else:
                                dt = datetime.fromisoformat(str(ts_str).replace("Z", "+00:00")).astimezone(jst)
                        except Exception:
                            continue

                        if dt < start_date: continue
                        d_key = dt.strftime("%Y-%m-%d")
                        u = msg["usage"]
                        c = u.get("cost", {})
                        cost = float(c.get("total", 0.0)) if isinstance(c, dict) else 0.0
                        inp = int(u.get("input", 0))
                        out = int(u.get("output", 0))
                        cr = int(u.get("cacheRead", 0))
                        cw = int(u.get("cacheWrite", 0))
                        tot = int(u.get("totalTokens") or (inp + out + cr + cw))
                        m_name = str(msg.get("model") or "unknown")

                        if d_key not in daily:
                            w_idx = dt.weekday()
                            w_name = weekday_names[w_idx]
                            daily[d_key] = {
                                "label": f"{d_key} ({w_name})",
                                "date": d_key,
                                "weekday": w_idx,
                                "input": 0,
                                "output": 0,
                                "cache_r": 0,
                                "cache_w": 0,
                                "total": 0,
                                "cost": 0.0,
                                "calls": 0
                            }
                        for target in (daily[d_key], totals):
                            target["input"] += inp
                            target["output"] += out
                            target["cache_r"] += cr
                            target["cache_w"] += cw
                            target["total"] += tot
                            target["cost"] += cost
                            target["calls"] += 1

                        m_key = (provider, m_name)
                        if m_key not in models:
                            models[m_key] = {"provider": provider, "model": m_name, "input": 0, "output": 0, "cache_r": 0, "cache_w": 0, "total": 0, "cost": 0.0, "calls": 0}
                        m = models[m_key]
                        m["input"] += inp
                        m["output"] += out
                        m["cache_r"] += cr
                        m["cache_w"] += cw
                        m["total"] += tot
                        m["cost"] += cost
                        m["calls"] += 1
    except Exception:
        pass

if args.csv:
    writer = csv.writer(sys.stdout)
    writer.writerow(["date", "calls", "input_tokens", "output_tokens", "cache_read", "cache_write", "total_tokens", "cost_usd"])
    for d, s in sorted(daily.items()):
        writer.writerow([s.get("date", d), s["calls"], s["input"], s["output"], s["cache_r"], s["cache_w"], s["total"], f"{s['cost']:.4f}"])
    writer.writerow(["total", totals["calls"], totals["input"], totals["output"], totals["cache_r"], totals["cache_w"], totals["total"], f"{totals['cost']:.4f}"])
    sys.exit(0)

CYAN = "\033[1;36m"
GREEN = "\033[1;32m"
YELLOW = "\033[1;33m"
BLUE = "\033[1;34m"
MAGENTA = "\033[1;35m"
RED = "\033[1;31m"
BOLD = "\033[1m"
DIM = "\033[2m"
RESET = "\033[0m"

w_date = 16
w_calls = 5
w_inp = 12
w_out = 10
w_cr = 12
w_cw = 12
w_tot = 14
w_cost = 11

col_widths = [w_date, w_calls, w_inp, w_out, w_cr, w_cw, w_tot, w_cost]
border_segments = [w + 2 for w in col_widths]
total_inner_width = sum(border_segments) + len(border_segments) - 1

top_border = f"┌{'─'*total_inner_width}┐"
mid_border = "├" + "┬".join("─" * bw for bw in border_segments) + "┤"
cross_border = "├" + "┼".join("─" * bw for bw in border_segments) + "┤"
bot_border = "└" + "┴".join("─" * bw for bw in border_segments) + "┘"

title = f" Pi Token & Cost Usage (Last {days} Days / JST) "

print(f"\n{BOLD}{CYAN}{top_border}{RESET}")
print(f"{BOLD}{CYAN}│{title.center(total_inner_width)}│{RESET}")
print(f"{BOLD}{CYAN}{mid_border}{RESET}")

h_date = pad_right("Date (JST)", w_date)
h_calls = f"{'Calls':>{w_calls}}"
h_inp = f"{'Input':>{w_inp}}"
h_out = f"{'Output':>{w_out}}"
h_cr = f"{'Cache Read':>{w_cr}}"
h_cw = f"{'Cache Write':>{w_cw}}"
h_tot = f"{'Total Tokens':>{w_tot}}"
h_cost = f"{'Cost (USD)':>{w_cost}}"

header_line = f"│ {h_date} │ {h_calls} │ {h_inp} │ {h_out} │ {h_cr} │ {h_cw} │ {h_tot} │ {h_cost} │"
print(f"{BOLD}{CYAN}{header_line}{RESET}")
print(f"{BOLD}{CYAN}{cross_border}{RESET}")

for d, s in sorted(daily.items()):
    cost_str = f"${s['cost']:.3f}"
    w_idx = s["weekday"]
    w_color = BLUE if w_idx == 5 else (RED if w_idx == 6 else RESET)
    p_label = pad_right(s["label"], w_date)

    d_calls = f"{s['calls']:>{w_calls},}"
    d_inp = f"{s['input']:>{w_inp},}"
    d_out = f"{s['output']:>{w_out},}"
    d_cr = f"{s['cache_r']:>{w_cr},}"
    d_cw = f"{s['cache_w']:>{w_cw},}"
    d_tot = f"{s['total']:>{w_tot},}"
    d_cost = f"{cost_str:>{w_cost}}"

    if s["calls"] == 0:
        row = f"│ {DIM}{p_label}{RESET} │ {DIM}{d_calls}{RESET} │ {DIM}{d_inp}{RESET} │ {DIM}{d_out}{RESET} │ {DIM}{d_cr}{RESET} │ {DIM}{d_cw}{RESET} │ {DIM}{d_tot}{RESET} │ {DIM}{d_cost}{RESET} │"
    else:
        row = f"│ {w_color}{p_label}{RESET} │ {d_calls} │ {d_inp} │ {d_out} │ {d_cr} │ {d_cw} │ {GREEN}{d_tot}{RESET} │ {YELLOW}{d_cost}{RESET} │"
    print(row)

print(f"{BOLD}{CYAN}{cross_border}{RESET}")
t_cost_str = f"${totals['cost']:.3f}"
t_label = pad_right("Total", w_date)
t_calls = f"{totals['calls']:>{w_calls},}"
t_inp = f"{totals['input']:>{w_inp},}"
t_out = f"{totals['output']:>{w_out},}"
t_cr = f"{totals['cache_r']:>{w_cr},}"
t_cw = f"{totals['cache_w']:>{w_cw},}"
t_tot = f"{totals['total']:>{w_tot},}"
t_cost = f"{t_cost_str:>{w_cost}}"

total_line = f"│ {BOLD}{t_label}{RESET} │ {BOLD}{t_calls}{RESET} │ {BOLD}{t_inp}{RESET} │ {BOLD}{t_out}{RESET} │ {BOLD}{t_cr}{RESET} │ {BOLD}{t_cw}{RESET} │ {BOLD}{GREEN}{t_tot}{RESET} │ {BOLD}{YELLOW}{t_cost}{RESET} │"
print(total_line)
print(f"{BOLD}{CYAN}{bot_border}{RESET}\n")

if models:
    print(f"{BOLD}Provider & Model Breakdown:{RESET}")
    max_prov_len = max(len(m["provider"]) for m in models.values())
    max_mod_len = max(len(m["model"]) for m in models.values())
    for (prov, mod), s in sorted(models.items(), key=lambda x: x[1]["cost"], reverse=True):
        m_cost = f"${s['cost']:.4f}"
        pct = (s["cost"] / totals["cost"] * 100) if totals["cost"] > 0 else 0
        bar_len = int(pct / 5)
        bar = "█" * bar_len
        p_str = f"{prov:<{max_prov_len}}"
        m_str = f"{mod:<{max_mod_len}}"
        print(f"  {BLUE}{p_str}{RESET} / {CYAN}{m_str}{RESET}  {s['calls']:>4,} calls  {GREEN}{s['total']:>12,} tokens{RESET}  {YELLOW}{m_cost:>9}{RESET}  {DIM}({pct:5.1f}%){RESET} {MAGENTA}{bar}{RESET}")
    print()
EOF
}
