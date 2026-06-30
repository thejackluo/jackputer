#!/usr/bin/env bash
set -euo pipefail

port="${1:-8000}"
chip_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

printf 'Serving p1-chip-gates/viz at http://localhost:%s/\n' "$port"
printf 'Try: http://localhost:%s/Mux/original/\n' "$port"
printf 'Try: http://localhost:%s/Mux/max/\n' "$port"
printf 'Try: http://localhost:%s/Mux8Way16/max/\n' "$port"

python3 -m http.server "$port" --directory "$chip_dir/viz"
