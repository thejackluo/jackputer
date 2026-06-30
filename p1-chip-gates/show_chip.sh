#!/usr/bin/env bash
set -euo pipefail

top="${1:-Mux}"
mode="${2:-svg}"

if [[ ! "$top" =~ ^[A-Za-z_][A-Za-z0-9_]*$ ]]; then
    printf 'invalid chip name: %s\n' "$top" >&2
    exit 2
fi

if ! command -v yosys >/dev/null 2>&1; then
    printf 'yosys is not installed. Try: sudo apt install -y yosys graphviz xdot\n' >&2
    exit 1
fi

chip_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$chip_dir"
mkdir -p viz

read_cmd='read_verilog v/*.v v-incomplete/*.v'
prep_cmd="hierarchy -check -top ${top}; proc; opt; check"
dot_file="viz/${top}.dot"
svg_file="viz/${top}.svg"

case "$mode" in
    svg)
        if ! command -v dot >/dev/null 2>&1; then
            printf 'graphviz dot is not installed. Try: sudo apt install -y graphviz\n' >&2
            exit 1
        fi
        yosys -q -p "${read_cmd}; ${prep_cmd}; show -format svg -viewer none -prefix viz/${top} ${top}"
        printf 'wrote p1-chip-gates/%s\n' "$svg_file"
        ;;
    dot)
        yosys -q -p "${read_cmd}; ${prep_cmd}; show -format dot -viewer none -prefix viz/${top} ${top}"
        printf 'wrote p1-chip-gates/%s\n' "$dot_file"
        ;;
    open)
        yosys -p "${read_cmd}; ${prep_cmd}; show ${top}"
        ;;
    *)
        printf 'usage: p1-chip-gates/show_chip.sh [ChipName] [svg|dot|open]\n' >&2
        exit 2
        ;;
esac
