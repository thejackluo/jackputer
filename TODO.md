# TODO

## HDL to Verilog

- Continue improving `p1-chip-gates/hdl_to_verilog.py` against more nand2tetris projects 2-5 examples as they are added.
- Keep support for scalar pins, buses, bus slices, indexed signals, constants, and repeated part instantiations covered.
- Keep generated Verilog structural so Yosys can show how each chip is built from smaller chips.
- Preserve `Nand.v` as the base primitive gate.

## Visualization

- Install Yosys and visualization tools with `sudo apt install -y yosys graphviz xdot` when needed.
- Validate generated Verilog with `p1-chip-gates/show_chip.sh Mux8Way16`.
- Add project-specific visualization examples as more chips are completed.
- Keep DigitalJS pages working via `p1-chip-gates/serve_viz.sh` when browser `file://` loading is unreliable.

## Future Chips

- Complete currently empty HDL files separately from generated compiler output.
- Regenerate Verilog after each chip HDL implementation is finished.
- Commit incomplete chip placeholders separately from completed chip conversions.
