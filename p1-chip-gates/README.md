# P1 Chip HDL to Verilog

This folder keeps nand2tetris HDL source files in `hdl/`, generated Verilog for completed chips in `v/`, and blackbox Verilog stubs for incomplete chips in `v-incomplete/`.

## Install Yosys

On Ubuntu or WSL Ubuntu:

```bash
sudo apt update
sudo apt install -y yosys graphviz xdot
```

`yosys` reads and synthesizes Verilog. `graphviz` and `xdot` let Yosys draw the circuit graph.

## Regenerate Verilog

Run this from the repository root:

```bash
python3 p1-chip-gates/hdl_to_verilog.py
```

The compiler always writes `p1-chip-gates/v/Nand.v` as the base NAND gate:

```verilog
assign out = ~(a & b);
```

Every completed chip is generated structurally from the `.hdl` file. Incomplete chips are emitted as empty blackbox modules in `v-incomplete/` when `--incomplete-output-dir` is used.

## Visualize A Chip

After installing Yosys, run one of these from the repository root:

```bash
p1-chip-gates/show_chip.sh Nand
p1-chip-gates/show_chip.sh Not
p1-chip-gates/show_chip.sh Mux
p1-chip-gates/show_chip.sh Mux8Way16
```

The default mode writes files under `p1-chip-gates/viz/`, including an SVG that opens directly in Cursor:

```text
p1-chip-gates/viz/Mux8Way16.svg
```

To ask Yosys to open its viewer directly, pass `open`. This may require WSL GUI support:

```bash
p1-chip-gates/show_chip.sh Mux8Way16 open
```

If you want a lower-level gate view, add synthesis passes before `show`:

```bash
yosys -p "read_verilog p1-chip-gates/v/*.v p1-chip-gates/v-incomplete/*.v; hierarchy -check -top Mux; proc; opt; techmap; opt; show"
```

For WSL without GUI support, prefer `p1-chip-gates/show_chip.sh`; it writes SVG files instead of trying to open a Linux window.

## How The Compiler Works

The script in `p1-chip-gates/hdl_to_verilog.py` does these compiler steps:

1. Strip comments from the `.hdl` file.
2. Parse `CHIP`, `IN`, `OUT`, and `PARTS` sections.
3. Find internal wires by looking for connected signals that are not top-level ports.
4. Infer internal scalar and bus wires from part connections.
5. Emit a Verilog `module` with structural submodule instances.
6. Emit incomplete HDL files separately as blackbox stubs when requested.

For example, this HDL:

```hdl
Nand(a=a, b=b, out=aNandb);
Not(in=aNandb, out=out);
```

becomes this Verilog:

```verilog
wire aNandb;

Nand nand_0(.a(a), .b(b), .out(aNandb));
Not not_1(.in(aNandb), .out(out));
```
