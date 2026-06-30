#!/usr/bin/env bash
set -euo pipefail

top="${1:-Mux}"
view="${2:-original}"
format="${3:-svg}"

case "$view" in
    svg|dot|open)
        format="$view"
        view="original"
        ;;
esac

if [[ "$top" != "all" && ! "$top" =~ ^[A-Za-z_][A-Za-z0-9_]*$ ]]; then
    printf 'invalid chip name: %s\n' "$top" >&2
    exit 2
fi

case "$view" in
    original|level[0-9]*|max|nand) ;;
    *)
        printf 'invalid view: %s\n' "$view" >&2
        printf 'usage: p1-chip-gates/show_chip.sh [ChipName|all] [original|level1|level2|max] [svg|dot|open]\n' >&2
        exit 2
        ;;
esac

if [[ "$view" == "nand" ]]; then
    view="max"
fi

if ! command -v yosys >/dev/null 2>&1; then
    printf 'yosys is not installed. Try: sudo apt install -y yosys graphviz xdot\n' >&2
    exit 1
fi

chip_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$chip_dir"
mkdir -p viz
shopt -s nullglob
verilog_files=(v/*.v v-incomplete/*.v)

if [[ ${#verilog_files[@]} -eq 0 ]]; then
    printf 'no Verilog files found. Run: python3 p1-chip-gates/hdl_to_verilog.py\n' >&2
    exit 1
fi

read_cmd="read_verilog ${verilog_files[*]}"

list_modules() {
    for file in v/*.v; do
        basename "$file" .v
    done | sort
}

flatten_cmd() {
    local selected_top="$1"
    local selected_view="$2"

    if [[ "$selected_view" == "original" ]]; then
        printf 'check'
        return
    fi

    python3 - "$selected_top" "$selected_view" "${verilog_files[@]}" <<'PY'
from __future__ import annotations

import re
import sys
from collections import deque
from pathlib import Path

top = sys.argv[1]
view = sys.argv[2]
paths = [Path(path) for path in sys.argv[3:]]
modules: set[str] = set()
deps: dict[str, set[str]] = {}
keywords = {"assign", "if", "for", "module", "wire"}

for path in paths:
    text = path.read_text()
    for match in re.finditer(r"\bmodule\s+(\w+)\s*\((.*?)\);(.*?)\bendmodule", text, flags=re.S):
        name = match.group(1)
        body = match.group(3)
        modules.add(name)
        deps.setdefault(name, set())
        for cell in re.finditer(r"^\s*(\w+)\s+\w+\s*\(", body, flags=re.M):
            module_name = cell.group(1)
            if module_name not in keywords:
                deps[name].add(module_name)

depth = {top: 0}
queue = deque([top])
while queue:
    current = queue.popleft()
    for child in sorted(deps.get(current, set())):
        if child in depth:
            continue
        depth[child] = depth[current] + 1
        queue.append(child)

keep = {"Nand"} if "Nand" in modules else set()
if view.startswith("level"):
    limit = int(view.removeprefix("level") or "0")
    keep.update(module for module, module_depth in depth.items() if module_depth > limit)

commands = []
for module in sorted(keep):
    if module != top:
        commands.append(f"setattr -mod -set keep_hierarchy 1 {module}")
commands.append(f"flatten {top}")
commands.append("opt_clean")
commands.append("check")
print("; ".join(commands))
PY
}

clean_dot_labels() {
    local dot_file="$1"

    python3 - "$dot_file" <<'PY'
from __future__ import annotations

import re
import sys
from pathlib import Path


def fmt_range(msb: str, lsb: str) -> str:
    return f"[{msb}]" if msb == lsb else f"[{msb}:{lsb}]"


path = Path(sys.argv[1])
text = path.read_text()

def replace(match: re.Match[str]) -> str:
    port = match.group(1)
    left = fmt_range(match.group(2), match.group(3))
    right = fmt_range(match.group(4), match.group(5))
    return f'{port}slice {left} to {right}'


def replace_single_label(match: re.Match[str]) -> str:
    left = fmt_range(match.group(1), match.group(2))
    right = fmt_range(match.group(3), match.group(4))
    return f'label="<s0> slice {left} to {right} "'

text = re.sub(r'(<s\d+>\s*)(\d+):(\d+)\s*-\s*(\d+):(\d+)', replace, text)
text = re.sub(r'label="<s0>\s*(\d+):(\d+)\s*-\s*(\d+):(\d+)\s*"', replace_single_label, text)
path.write_text(text)
PY
}

generate_one() {
    local selected_top="$1"
    local selected_view="$2"
    local selected_format="$3"
    local prefix="viz/${selected_top}.${selected_view}"
    local dot_file="${prefix}.dot"
    local svg_file="${prefix}.svg"
    local prep_cmd

    prep_cmd="hierarchy -check -top ${selected_top}; proc; opt; $(flatten_cmd "$selected_top" "$selected_view")"

    case "$selected_format" in
        svg)
            if ! command -v dot >/dev/null 2>&1; then
                printf 'graphviz dot is not installed. Try: sudo apt install -y graphviz\n' >&2
                exit 1
            fi
            yosys -q -p "${read_cmd}; ${prep_cmd}; show -format dot -viewer none -prefix ${prefix} ${selected_top}"
            clean_dot_labels "$dot_file"
            dot -Tsvg "$dot_file" -o "$svg_file"
            printf 'wrote p1-chip-gates/%s\n' "$svg_file"
            ;;
        dot)
            yosys -q -p "${read_cmd}; ${prep_cmd}; show -format dot -viewer none -prefix ${prefix} ${selected_top}"
            clean_dot_labels "$dot_file"
            printf 'wrote p1-chip-gates/%s\n' "$dot_file"
            ;;
        open)
            yosys -p "${read_cmd}; ${prep_cmd}; show ${selected_top}"
            ;;
        *)
            printf 'usage: p1-chip-gates/show_chip.sh [ChipName|all] [original|level1|level2|max] [svg|dot|open]\n' >&2
            exit 2
            ;;
    esac
}

if [[ "$top" == "all" ]]; then
    for module in $(list_modules); do
        generate_one "$module" "$view" "$format"
    done
else
    generate_one "$top" "$view" "$format"
fi
