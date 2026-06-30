# Jacputer

Jacputer is my nand2tetris computer build. The chips are written in HDL, compiled into structural Verilog, and rendered into interactive browser visualizations so the design can be explored from high-level blocks down to primitive NAND gates.

## View The Site

Open the generated site from the repository root:

```bash
./serve_viz.sh
```

Then visit:

```text
http://localhost:8000/index.html
```

The root `index.html` is suitable for GitHub Pages. It links into the generated `viz/` directory, including the ALU views:

```text
viz/ALU/original/index.html
viz/ALU/max/index.html
```

## Projects

- `p1-chip-gates/`: project 1 gates, HDL compiler, and visualization tooling.
- `p2-alu-chip/`: project 2 arithmetic chips and ALU.
- `viz/`: generated interactive and SVG visualizations for all compiled chips.

## Visualization Levels

- `original`: show the chip using its immediate subchips.
- `level1`: expand one dependency layer.
- `level2`: expand two dependency layers.
- `max`: recursively expand to primitive `Nand` leaves.

`Nand` is treated as the foundational primitive. It is not expanded into `And` plus `Not`.

## Rebuild

Install tools on Ubuntu/WSL:

```bash
sudo apt install -y yosys graphviz
npm install
```

Regenerate project 1 Verilog:

```bash
python3 p1-chip-gates/hdl_to_verilog.py
```

Regenerate project 2 Verilog using project 1 interfaces:

```bash
python3 p1-chip-gates/hdl_to_verilog.py p2-alu-chip p2-alu-chip/v --interface-dir p1-chip-gates/hdl --incomplete-output-dir p2-alu-chip/v-incomplete --no-nand
```

Regenerate visualizations and the root site index:

```bash
./show_chip.sh all all-levels all
```

## Notes

The interactive pages include layout switching, zoom controls, fit-to-screen, and Ctrl/Cmd-wheel zoom for large circuits like `ALU/max`.
