#!/usr/bin/env bash
set -euo pipefail

port="${1:-8000}"
script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(cd "$script_dir/.." && pwd)"

printf 'Serving viz at http://localhost:%s/\n' "$port"
printf 'Try: http://localhost:%s/index.html\n' "$port"
printf 'Try: http://localhost:%s/Mux/original/index.html\n' "$port"
printf 'Try: http://localhost:%s/Mux/max/index.html\n' "$port"
printf 'Try: http://localhost:%s/Mux8Way16/max/index.html\n' "$port"

python3 -m http.server "$port" --directory "$repo_root/viz"
