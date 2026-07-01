# Jacputer

Jacputer is my nand2tetris computer build. The chips are written in HDL, compiled into structural Verilog, and rendered into interactive browser visualizations so the design can be explored from high-level blocks down to primitive NAND gates. The goal for this project is to build a computer from scratch starting from the universial nand gates all the way up

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
- `p3-ram-pc/`: project 3 memory chips and program counter.
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

Regenerate project 3 RAM Verilog using earlier projects as interfaces:

```bash
python3 p1-chip-gates/hdl_to_verilog.py p3-ram-pc p3-ram-pc/v --interface-dir p1-chip-gates/hdl --interface-dir p2-alu-chip --incomplete-output-dir p3-ram-pc/v-incomplete --no-nand --dff-blackbox
```

Regenerate visualizations and the root site index:

```bash
./show_chip.sh all all-levels all
```

## Notes

The interactive pages include layout switching, zoom controls, fit-to-screen, and Ctrl/Cmd-wheel zoom for large circuits like `ALU/max`.

Large RAM chips are guarded from impractical flat expansion. `RAM16K/max` exists as a hierarchical max page with counts and drill-down links instead of a single enormous canvas. By default, `RAM64` uses a hierarchical `max`, and `RAM512`, `RAM4K`, and `RAM16K` use hierarchical `level2` and `max` pages. Set `ALLOW_HUGE_LEVEL2=1` or `ALLOW_HUGE_MAX=1` when invoking `./show_chip.sh` if you explicitly want to force flat generation.

`PC/original` and `PC/level1` render as circuits. Deeper PC views use hierarchical pages because the register feedback loop makes flat graph layout impractical right now.

Sequential chips use `DFF` as a primitive leaf. The DigitalJS pages add an implicit shared clock for DFF devices and cache laid-out circuit positions in the browser with IndexedDB, so repeat visits can avoid recomputing large layouts.
