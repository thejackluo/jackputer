#!/usr/bin/env python3
"""Build navigation pages for generated chip visualizations."""

from __future__ import annotations

import html
import re
from collections import Counter
from pathlib import Path


SCRIPT_DIR = Path(__file__).resolve().parent
REPO_ROOT = SCRIPT_DIR.parent
VIZ = REPO_ROOT / "viz"
LEVELS = ["original", "level1", "level2", "max"]
KEYWORDS = {"assign", "if", "for", "module", "wire"}


def parse_modules() -> dict[str, Counter[str]]:
    modules: dict[str, Counter[str]] = {}
    for path in sorted(REPO_ROOT.glob("*/v/*.v")):
        text = path.read_text()
        for match in re.finditer(r"\bmodule\s+(\w+)\s*\((.*?)\);(.*?)\bendmodule", text, flags=re.S):
            name = match.group(1)
            body = match.group(3)
            deps: Counter[str] = Counter()
            for cell in re.finditer(r"^\s*(\w+)\s+\w+\s*\(", body, flags=re.M):
                module_name = cell.group(1)
                if module_name not in KEYWORDS:
                    deps[module_name] += 1
            modules[name] = deps
    return modules


def level_links(gate: str, link_prefix: str = "") -> str:
    links = []
    for level in LEVELS:
        base = VIZ / gate / level
        html_path = base / "index.html"
        svg_path = base / "circuit.svg"
        if html_path.exists():
            links.append(f'<a href="{link_prefix}{gate}/{level}/index.html">{level}</a>')
        if svg_path.exists():
            links.append(f'<a class="secondary" href="{link_prefix}{gate}/{level}/circuit.svg">svg</a>')
    return " ".join(links)


def child_links(deps: Counter[str], link_prefix: str = "") -> str:
    if not deps:
        return '<span class="muted">leaf</span>'
    parts = []
    for child, count in sorted(deps.items()):
        href = f'{link_prefix}{child}/original/index.html' if (VIZ / child / "original" / "index.html").exists() else "#"
        label = f'{count}x {html.escape(child)}' if count > 1 else html.escape(child)
        parts.append(f'<a href="{href}">{label}</a>')
    return ", ".join(parts)


def build_index(modules: dict[str, Counter[str]], output_path: Path, link_prefix: str = "") -> None:
    rows = []
    for gate in sorted(modules):
        rows.append(
            "<tr>"
            f"<th>{html.escape(gate)}</th>"
            f"<td>{level_links(gate, link_prefix)}</td>"
            f"<td>{child_links(modules[gate], link_prefix)}</td>"
            "</tr>"
        )

    page = f"""<!doctype html>
<html>
  <head>
    <meta charset="utf-8">
    <title>Chip Visualizations</title>
    <style>
      body {{ margin: 0; font-family: system-ui, sans-serif; line-height: 1.45; color: #1f2937; }}
      main {{ max-width: 1180px; margin: 0 auto; padding: 28px; }}
      h1 {{ margin: 0 0 8px; font-size: clamp(2rem, 5vw, 4rem); letter-spacing: -0.05em; }}
      .lede {{ color: #475569; font-size: 1.1rem; max-width: 860px; }}
      .hero {{ display: grid; gap: 16px; margin-bottom: 20px; }}
      .quick-links {{ display: flex; flex-wrap: wrap; gap: 10px; margin: 18px 0 4px; }}
      .quick-links a {{ background: #0f172a; color: white; border-radius: 999px; padding: 8px 12px; }}
      .quick-links a.secondary-link {{ background: #e2e8f0; color: #0f172a; }}
      table {{ border-collapse: collapse; width: 100%; }}
      th, td {{ border-bottom: 1px solid #e5e7eb; padding: 10px; text-align: left; vertical-align: top; }}
      th {{ width: 140px; }}
      a {{ display: inline-block; margin: 0 8px 6px 0; color: #075985; text-decoration: none; font-weight: 600; }}
      a:hover {{ text-decoration: underline; }}
      .secondary {{ color: #64748b; font-weight: 500; }}
      .muted {{ color: #64748b; }}
      .note {{ background: #f8fafc; border: 1px solid #e2e8f0; border-radius: 8px; padding: 12px 16px; margin: 16px 0 24px; }}
      code {{ background: #f1f5f9; padding: 2px 5px; border-radius: 4px; }}
    </style>
  </head>
  <body>
    <main>
      <section class="hero">
        <h1>Jacputer Chip Visualizations</h1>
        <p class="lede">A growing nand2tetris computer, compiled from hand-written HDL into Verilog and interactive browser schematics. Start with the ALU, then descend through the levels until the whole thing bottoms out at primitive NAND gates.</p>
        <div class="quick-links">
          <a href="{link_prefix}ALU/original/index.html">Open ALU</a>
          <a href="{link_prefix}ALU/max/index.html">ALU NAND-expanded</a>
          <a class="secondary-link" href="{link_prefix}Mux16/original/index.html">Mux16</a>
          <a class="secondary-link" href="{link_prefix}Nand/original/index.html">Primitive NAND</a>
        </div>
      </section>
      <div class="note">
        <p><strong>Use this page as the circuit map.</strong> It is generated from project Verilog folders such as <code>p1-chip-gates/v/</code>. Each gate has <code>original</code>, <code>level1</code>, <code>level2</code>, and <code>max</code> views.</p>
        <p><code>original</code> keeps immediate subchips boxed. <code>level1</code> expands one layer. <code>level2</code> expands two layers. <code>max</code> expands recursively down to <code>Nand</code> leaves.</p>
        <p>Flattened views preserve instance names such as <code>mux_0.and_1</code>, but Yosys does not draw nested boxes around each expanded instance. Use the child links to jump into each subchip directly.</p>
      </div>
      <table>
        <thead><tr><th>Gate</th><th>Views</th><th>Immediate Subchips</th></tr></thead>
        <tbody>
          {''.join(rows)}
        </tbody>
      </table>
    </main>
  </body>
</html>
"""
    output_path.parent.mkdir(parents=True, exist_ok=True)
    output_path.write_text(page)
    print(f"wrote {output_path}")


def main() -> None:
    modules = parse_modules()
    build_index(modules, VIZ / "index.html")
    build_index(modules, REPO_ROOT / "index.html", "viz/")


if __name__ == "__main__":
    main()
