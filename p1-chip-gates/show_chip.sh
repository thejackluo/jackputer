#!/usr/bin/env bash
set -euo pipefail

top="${1:-Mux}"
view="${2:-original}"
format="${3:-svg}"
levels=(original level1 level2 max)
huge_max_modules=(PC RAM64 RAM512 RAM4K RAM16K)
huge_level2_modules=(PC RAM512 RAM4K RAM16K)

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
    original|level[0-9]*|max|nand|all-levels) ;;
    *)
        printf 'invalid view: %s\n' "$view" >&2
        printf 'usage: p1-chip-gates/show_chip.sh [ChipName|all] [original|level1|level2|max|all-levels] [svg|dot|digitaljs|all|open]\n' >&2
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

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(cd "$script_dir/.." && pwd)"
cd "$repo_root"
viz_dir="viz"
mkdir -p "$viz_dir"
shopt -s nullglob
source_verilog_files=(*/v/*.v */v-incomplete/*.v)
verilog_files=()

if [[ ${#source_verilog_files[@]} -eq 0 ]]; then
    printf 'no Verilog files found. Run: python3 p1-chip-gates/hdl_to_verilog.py\n' >&2
    exit 1
fi

nand_primitive="$viz_dir/.NandPrimitive.v"
cat > "$nand_primitive" <<'EOF'
(* blackbox *)
module Nand(
    input wire a,
    input wire b,
    output wire out
);
endmodule
EOF
trap 'rm -f "$nand_primitive"' EXIT

for file in "${source_verilog_files[@]}"; do
    if [[ "$(basename "$file")" != "Nand.v" ]]; then
        verilog_files+=("$file")
    fi
done
verilog_files+=("$nand_primitive")

read_cmd="read_verilog ${verilog_files[*]}"

list_modules() {
    for file in */v/*.v; do
        basename "$file" .v
    done | sort
}

flatten_cmd() {
    local selected_top="$1"
    local selected_view="$2"
    shift 2
    local extra_verilog_files=("$@")

    if [[ "$selected_view" == "original" || "$selected_top" == "NandPrimitiveView" ]]; then
        printf 'check'
        return
    fi

    python3 - "$selected_top" "$selected_view" "${verilog_files[@]}" "${extra_verilog_files[@]}" <<'PY'
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
    if module != top and module not in {"Nand", "DFF"}:
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

huge_child_module() {
    case "$1" in
        RAM16K) printf 'RAM4K' ;;
        RAM4K) printf 'RAM512' ;;
        RAM512) printf 'RAM64' ;;
        RAM64) printf 'RAM8' ;;
        *) printf '' ;;
    esac
}

huge_summary() {
    case "$1" in
        RAM64) printf 'RAM64 expands to 8 RAM8 chips, 64 registers, and 1,024 one-bit storage cells.' ;;
        RAM512) printf 'RAM512 expands to 8 RAM64 chips, 512 registers, and 8,192 one-bit storage cells.' ;;
        RAM4K) printf 'RAM4K expands to 8 RAM512 chips, 4,096 registers, and 65,536 one-bit storage cells.' ;;
        RAM16K) printf 'RAM16K expands to 4 RAM4K chips, 16,384 registers, and 262,144 one-bit storage cells.' ;;
        PC) printf 'PC expands through Register feedback, increment logic, and mux control. Deeper flat graph layouts are currently impractical because of the sequential feedback loop.' ;;
        *) printf 'This RAM view is too large for a practical flat browser render.' ;;
    esac
}

generate_huge_page() {
    local selected_top="$1"
    local selected_view="$2"
    local output_dir="${viz_dir}/${selected_top}/${selected_view}"
    local child
    local summary

    mkdir -p "$output_dir"
    child="$(huge_child_module "$selected_top")"
    summary="$(huge_summary "$selected_top")"

    cat > "${output_dir}/index.html" <<EOF
<!doctype html>
<html>
  <head>
    <meta charset="utf-8">
    <title>${selected_top} ${selected_view} Hierarchical View</title>
    <style>
      body { margin: 0; font-family: system-ui, sans-serif; line-height: 1.5; color: #1f2937; }
      main { max-width: 900px; margin: 0 auto; padding: 28px; }
      a { color: #075985; font-weight: 650; text-decoration: none; }
      a:hover { text-decoration: underline; }
      .card { border: 1px solid #e2e8f0; border-radius: 12px; background: #f8fafc; padding: 16px; margin: 16px 0; }
      code { background: #e2e8f0; padding: 2px 5px; border-radius: 4px; }
      li { margin: 6px 0; }
    </style>
  </head>
  <body>
    <main>
      <p><a href="../../index.html">All gates</a></p>
      <h1>${selected_top} ${selected_view}</h1>
      <div class="card">
        <p><strong>Hierarchical max view.</strong> ${summary}</p>
        <p>A flat DigitalJS render at this depth would create too many browser nodes and wires to be useful. This page keeps the full expansion navigable as a memory hierarchy instead of generating one enormous canvas.</p>
      </div>
      <h2>Available Views</h2>
      <ul>
        <li><a href="../original/index.html">${selected_top} original</a></li>
        <li><a href="../level1/index.html">${selected_top} level1</a></li>
EOF
    if [[ -e "${viz_dir}/${selected_top}/level2/index.html" ]]; then
        printf '        <li><a href="../level2/index.html">%s level2</a></li>\n' "$selected_top" >> "${output_dir}/index.html"
    fi
    if [[ -n "$child" ]]; then
        cat >> "${output_dir}/index.html" <<EOF
      </ul>
      <h2>Drill Down</h2>
      <ul>
        <li><a href="../../${child}/original/index.html">${child} original</a></li>
        <li><a href="../../${child}/max/index.html">${child} max / deepest practical view</a></li>
      </ul>
EOF
    else
        printf '      </ul>\n' >> "${output_dir}/index.html"
    fi
    cat >> "${output_dir}/index.html" <<EOF
      <div class="card">
        <p>To force flat generation anyway, run with <code>ALLOW_HUGE_LEVEL2=1</code> or <code>ALLOW_HUGE_MAX=1</code>. Expect long generation times and poor browser performance for large RAMs.</p>
      </div>
    </main>
  </body>
</html>
EOF
    printf 'wrote %s\n' "${output_dir}/index.html"
}

generate_one() {
    local selected_top="$1"
    local selected_view="$2"
    local selected_format="$3"
    local output_dir="${viz_dir}/${selected_top}/${selected_view}"
    local prefix="${output_dir}/circuit"
    local dot_file="${prefix}.dot"
    local svg_file="${prefix}.svg"
    local json_file="${prefix}.yosys.json"
    local prep_cmd
    local yosys_top="$selected_top"
    local selected_read_cmd="$read_cmd"
    local nand_wrapper=""
    local extra_flatten_files=()

    if [[ "$selected_view" == "max" ]]; then
        for huge_module in "${huge_max_modules[@]}"; do
            if [[ "$selected_top" == "$huge_module" && "${ALLOW_HUGE_MAX:-0}" != "1" ]]; then
                generate_huge_page "$selected_top" "$selected_view"
                return
            fi
        done
    fi
    if [[ "$selected_view" == "level2" ]]; then
        for huge_module in "${huge_level2_modules[@]}"; do
            if [[ "$selected_top" == "$huge_module" && "${ALLOW_HUGE_LEVEL2:-0}" != "1" ]]; then
                generate_huge_page "$selected_top" "$selected_view"
                return
            fi
        done
    fi

    mkdir -p "$output_dir"
    if [[ "$selected_top" == "Nand" ]]; then
        yosys_top="NandPrimitiveView"
        nand_wrapper="${output_dir}/.NandPrimitiveView.v"
        cat > "$nand_wrapper" <<'EOF'
module NandPrimitiveView(
    input wire a,
    input wire b,
    output wire out
);
    Nand nand_gate(.a(a), .b(b), .out(out));
endmodule
EOF
        selected_read_cmd="${read_cmd} ${nand_wrapper}"
        extra_flatten_files+=("$nand_wrapper")
    fi

    prep_cmd="hierarchy -check -top ${yosys_top}; proc; opt; $(flatten_cmd "$yosys_top" "$selected_view" "${extra_flatten_files[@]}")"

    case "$selected_format" in
        svg)
            if ! command -v dot >/dev/null 2>&1; then
                printf 'graphviz dot is not installed. Try: sudo apt install -y graphviz\n' >&2
                exit 1
            fi
            yosys -q -p "${selected_read_cmd}; ${prep_cmd}; show -format dot -viewer none -prefix ${prefix} ${yosys_top}"
            clean_dot_labels "$dot_file"
            dot -Tsvg "$dot_file" -o "$svg_file"
            printf 'wrote %s\n' "$svg_file"
            ;;
        dot)
            yosys -q -p "${selected_read_cmd}; ${prep_cmd}; show -format dot -viewer none -prefix ${prefix} ${yosys_top}"
            clean_dot_labels "$dot_file"
            printf 'wrote %s\n' "$dot_file"
            ;;
        digitaljs)
            if ! command -v node >/dev/null 2>&1; then
                printf 'node is not installed. Install Node.js or use nvm, then run: npm install\n' >&2
                exit 1
            fi
            if [[ ! -d node_modules/yosys2digitaljs || ! -d node_modules/digitaljs ]]; then
                printf 'DigitalJS dependencies are not installed. Run: npm install\n' >&2
                exit 1
            fi
            yosys -q -p "${selected_read_cmd}; ${prep_cmd}; write_json ${json_file}"
            node "$script_dir/digitaljs_export.js" "$json_file" "$output_dir" "${selected_top} ${selected_view}"
            rm -f "$json_file"
            ;;
        all)
            generate_one "$selected_top" "$selected_view" svg
            generate_one "$selected_top" "$selected_view" digitaljs
            ;;
        open)
            yosys -p "${selected_read_cmd}; ${prep_cmd}; show ${yosys_top}"
            ;;
        *)
            printf 'usage: p1-chip-gates/show_chip.sh [ChipName|all] [original|level1|level2|max|all-levels] [svg|dot|digitaljs|all|open]\n' >&2
            exit 2
            ;;
    esac

    if [[ -n "$nand_wrapper" ]]; then
        rm -f "$nand_wrapper"
    fi
}

generate_views() {
    local selected_top="$1"
    local selected_view="$2"
    local selected_format="$3"

    if [[ "$selected_view" == "all-levels" ]]; then
        for level in "${levels[@]}"; do
            generate_one "$selected_top" "$level" "$selected_format"
        done
    else
        generate_one "$selected_top" "$selected_view" "$selected_format"
    fi
}

if [[ "$top" == "all" ]]; then
    for module in $(list_modules); do
        generate_views "$module" "$view" "$format"
    done
else
    generate_views "$top" "$view" "$format"
fi

if [[ "$format" != "open" ]]; then
    python3 "$script_dir/build_viz_index.py"
fi

rm -f "$nand_primitive"
