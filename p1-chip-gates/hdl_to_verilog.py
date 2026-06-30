#!/usr/bin/env python3
"""Convert nand2tetris HDL files to structural Verilog."""

from __future__ import annotations

import argparse
import re
from dataclasses import dataclass
from pathlib import Path


NAND_VERILOG = """module Nand(
    input wire a,
    input wire b,
    output wire out
);
    assign out = ~(a & b);
endmodule
"""


@dataclass(frozen=True)
class Pin:
    name: str
    width: int = 1
    direction: str = "input"


@dataclass(frozen=True)
class Ref:
    name: str
    lo: int | None = None
    hi: int | None = None
    const: str | None = None

    @property
    def is_const(self) -> bool:
        return self.const is not None

    @property
    def width(self) -> int | None:
        if self.is_const:
            return None
        if self.lo is None:
            return None
        return self.hi - self.lo + 1

    @property
    def is_slice(self) -> bool:
        return self.lo is not None

    @property
    def base(self) -> str:
        return self.name


@dataclass(frozen=True)
class Connection:
    pin: Ref
    signal: Ref


@dataclass(frozen=True)
class Part:
    chip: str
    connections: list[Connection]


@dataclass(frozen=True)
class Chip:
    name: str
    inputs: list[Pin]
    outputs: list[Pin]
    parts: list[Part]
    path: Path

    @property
    def pins(self) -> dict[str, Pin]:
        return {pin.name: pin for pin in self.inputs + self.outputs}

    @property
    def complete(self) -> bool:
        return bool(self.parts)


BUILTINS: dict[str, Chip] = {
    "Nand": Chip("Nand", [Pin("a"), Pin("b")], [Pin("out", direction="output")], [], Path("<builtin>")),
    "DFF": Chip("DFF", [Pin("in")], [Pin("out", direction="output")], [], Path("<builtin>")),
    "Register": Chip("Register", [Pin("in", 16), Pin("load")], [Pin("out", 16, "output")], [], Path("<builtin>")),
    "ARegister": Chip("ARegister", [Pin("in", 16), Pin("load")], [Pin("out", 16, "output")], [], Path("<builtin>")),
    "DRegister": Chip("DRegister", [Pin("in", 16), Pin("load")], [Pin("out", 16, "output")], [], Path("<builtin>")),
    "PC": Chip("PC", [Pin("in", 16), Pin("load"), Pin("inc"), Pin("reset")], [Pin("out", 16, "output")], [], Path("<builtin>")),
    "ROM32K": Chip("ROM32K", [Pin("address", 15)], [Pin("out", 16, "output")], [], Path("<builtin>")),
    "Screen": Chip("Screen", [Pin("in", 16), Pin("load"), Pin("address", 13)], [Pin("out", 16, "output")], [], Path("<builtin>")),
    "Keyboard": Chip("Keyboard", [], [Pin("out", 16, "output")], [], Path("<builtin>")),
}


def remove_comments(text: str) -> str:
    text = re.sub(r"/\*.*?\*/", "", text, flags=re.S)
    return re.sub(r"//.*", "", text)


def split_csv(text: str) -> list[str]:
    return [item.strip() for item in text.split(",") if item.strip()]


def parse_width(raw_width: str | None) -> int:
    return int(raw_width) if raw_width else 1


def parse_pin(token: str, direction: str) -> Pin:
    match = re.fullmatch(r"([A-Za-z_]\w*)(?:\[(\d+)\])?", token.strip())
    if not match:
        raise ValueError(f"invalid pin declaration: {token!r}")
    return Pin(match.group(1), parse_width(match.group(2)), direction)


def parse_ref(token: str) -> Ref:
    token = token.strip()
    if token in {"true", "false"}:
        return Ref(token, const=token)

    match = re.fullmatch(r"([A-Za-z_]\w*)(?:\[(\d+)(?:\.\.(\d+))?\])?", token)
    if not match:
        raise ValueError(f"invalid signal reference: {token!r}")

    name = match.group(1)
    if match.group(2) is None:
        return Ref(name)

    first = int(match.group(2))
    second = int(match.group(3)) if match.group(3) is not None else first
    lo, hi = sorted((first, second))
    return Ref(name, lo, hi)


def parse_port_section(body: str, keyword: str, direction: str) -> list[Pin]:
    match = re.search(rf"\b{keyword}\b\s+(.*?);", body, flags=re.S)
    if not match:
        return []
    return [parse_pin(token, direction) for token in split_csv(match.group(1))]


def parse_parts(body: str) -> list[Part]:
    match = re.search(r"\bPARTS\s*:\s*(.*)", body, flags=re.S)
    if not match:
        return []

    parts = []
    for chip_name, args_text in re.findall(r"([A-Za-z_]\w*)\s*\((.*?)\)\s*;", match.group(1), flags=re.S):
        connections = []
        for arg in split_csv(args_text):
            if "=" not in arg:
                raise ValueError(f"invalid connection in {chip_name}: {arg!r}")
            pin, signal = arg.split("=", 1)
            connections.append(Connection(parse_ref(pin), parse_ref(signal)))
        parts.append(Part(chip_name, connections))
    return parts


def parse_hdl(path: Path) -> Chip | None:
    source = path.read_text()
    if not source.strip():
        return None

    text = remove_comments(source)
    match = re.search(r"\bCHIP\s+([A-Za-z_]\w*)\s*\{(.*)\}\s*$", text, flags=re.S)
    if not match:
        raise ValueError(f"{path}: could not find CHIP declaration")

    name = match.group(1)
    body = match.group(2)
    return Chip(
        name=name,
        inputs=parse_port_section(body, "IN", "input"),
        outputs=parse_port_section(body, "OUT", "output"),
        parts=parse_parts(body),
        path=path,
    )


def discover_chips(input_dir: Path, recursive: bool) -> dict[str, Chip]:
    pattern = "**/*.hdl" if recursive else "*.hdl"
    chips: dict[str, Chip] = {}
    for path in sorted(input_dir.glob(pattern)):
        chip = parse_hdl(path)
        if chip is None:
            print(f"skip empty {path}")
            continue
        if chip.name in chips:
            raise ValueError(f"duplicate CHIP {chip.name}: {chips[chip.name].path} and {path}")
        chips[chip.name] = chip
    return chips


def pin_width(interface: Chip | None, ref: Ref) -> int:
    if ref.is_slice:
        return ref.width or 1
    if interface and ref.base in interface.pins:
        return interface.pins[ref.base].width
    return 1


def pin_direction(interface: Chip | None, ref: Ref) -> str:
    if interface and ref.base in interface.pins:
        return interface.pins[ref.base].direction
    if ref.base in {"out", "zr", "ng", "outM", "writeM", "addressM", "pc"}:
        return "output"
    return "input"


def ref_width(ref: Ref, expected_width: int) -> int:
    if ref.is_const:
        return expected_width
    return ref.width or expected_width


def update_width(widths: dict[str, int], ref: Ref, expected_width: int, ports: set[str]) -> None:
    if ref.is_const or ref.base in ports:
        return
    width = ref_width(ref, expected_width)
    if ref.is_slice:
        width = max(width, (ref.hi or 0) + 1)
    widths[ref.base] = max(widths.get(ref.base, 1), width)


def const_expr(value: str, width: int) -> str:
    bit = "1" if value == "true" else "0"
    if width == 1:
        return f"1'b{bit}"
    return f"{{{width}{{1'b{bit}}}}}"


def verilog_ref(ref: Ref, width: int = 1) -> str:
    if ref.is_const:
        return const_expr(ref.const or "false", width)
    if ref.is_slice:
        if ref.lo == ref.hi:
            return f"{ref.name}[{ref.lo}]"
        return f"{ref.name}[{ref.hi}:{ref.lo}]"
    return ref.name


def port_decl(pin: Pin) -> str:
    if pin.width == 1:
        return f"    {pin.direction} wire {pin.name}"
    return f"    {pin.direction} wire [{pin.width - 1}:0] {pin.name}"


def temp_name(part_index: int, pin_name: str) -> str:
    return f"_{part_index}_{pin_name}_wire"


def infer_internal_widths(chip: Chip, interfaces: dict[str, Chip]) -> dict[str, int]:
    ports = {pin.name for pin in chip.inputs + chip.outputs}
    widths: dict[str, int] = {}

    for part in chip.parts:
        interface = interfaces.get(part.chip)
        for connection in part.connections:
            expected_width = pin_width(interface, connection.pin)
            update_width(widths, connection.signal, expected_width, ports)

    return widths


def output_groups(part: Part, interface: Chip | None) -> dict[str, list[Connection]]:
    groups: dict[str, list[Connection]] = {}
    for connection in part.connections:
        if pin_direction(interface, connection.pin) != "output":
            continue
        groups.setdefault(connection.pin.base, []).append(connection)
    return groups


def needs_temp(connections: list[Connection]) -> bool:
    return len(connections) > 1 or any(connection.pin.is_slice for connection in connections)


def emit_chip(chip: Chip, interfaces: dict[str, Chip], blackbox: bool = False) -> str:
    lines = [f"module {chip.name}("]
    pins = chip.inputs + chip.outputs
    for index, pin in enumerate(pins):
        suffix = "," if index < len(pins) - 1 else ""
        lines.append(port_decl(pin) + suffix)
    lines.append(");")

    if blackbox or not chip.parts:
        lines.append("endmodule")
        lines.append("")
        return "\n".join(lines)

    wires = infer_internal_widths(chip, interfaces)
    temp_wires: dict[tuple[int, str], int] = {}
    for part_index, part in enumerate(chip.parts):
        interface = interfaces.get(part.chip)
        for pin_name, connections in output_groups(part, interface).items():
            if needs_temp(connections):
                temp_wires[(part_index, pin_name)] = pin_width(interface, connections[0].pin)

    wire_lines = []
    for name, width in sorted(wires.items()):
        if width == 1:
            wire_lines.append(f"    wire {name};")
        else:
            wire_lines.append(f"    wire [{width - 1}:0] {name};")
    for (part_index, pin_name), width in sorted(temp_wires.items()):
        name = temp_name(part_index, pin_name)
        if width == 1:
            wire_lines.append(f"    wire {name};")
        else:
            wire_lines.append(f"    wire [{width - 1}:0] {name};")

    if wire_lines:
        lines.extend(wire_lines)
        lines.append("")

    for part_index, part in enumerate(chip.parts):
        interface = interfaces.get(part.chip)
        temp_outputs = {pin_name for (idx, pin_name) in temp_wires if idx == part_index}
        connected_ports: set[str] = set()
        port_exprs: list[str] = []
        post_assigns: list[str] = []

        for pin_name, connections in output_groups(part, interface).items():
            if pin_name not in temp_outputs:
                continue
            temp = temp_name(part_index, pin_name)
            port_exprs.append(f".{pin_name}({temp})")
            connected_ports.add(pin_name)
            for connection in connections:
                source = Ref(temp, connection.pin.lo, connection.pin.hi) if connection.pin.is_slice else Ref(temp)
                post_assigns.append(f"    assign {verilog_ref(connection.signal)} = {verilog_ref(source)};")

        for connection in part.connections:
            pin_name = connection.pin.base
            if pin_name in connected_ports:
                continue
            expected_width = pin_width(interface, connection.pin)
            expr = verilog_ref(connection.signal, expected_width)
            port_exprs.append(f".{pin_name}({expr})")
            connected_ports.add(pin_name)

        instance = f"{part.chip.lower()}_{part_index}"
        lines.append(f"    {part.chip} {instance}({', '.join(port_exprs)});")
        lines.extend(post_assigns)

    lines.append("endmodule")
    lines.append("")
    return "\n".join(lines)


def write_generated(path: Path, text: str) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(text)
    print(f"wrote {path}")


def clean_generated(*dirs: Path | None) -> None:
    seen: set[Path] = set()
    for directory in dirs:
        if directory is None:
            continue
        resolved = directory.resolve()
        if resolved in seen or not directory.exists():
            continue
        seen.add(resolved)
        for path in directory.glob("*.v"):
            path.unlink()


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    script_dir = Path(__file__).resolve().parent
    parser.add_argument("input_dir", type=Path, nargs="?", default=script_dir / "hdl", help="directory containing .hdl files")
    parser.add_argument("output_dir", type=Path, nargs="?", default=script_dir / "v", help="directory for completed generated .v files")
    parser.add_argument("--recursive", action="store_true", help="read .hdl files recursively")
    parser.add_argument("--incomplete-output-dir", type=Path, default=script_dir / "v-incomplete", help="write blackbox stubs for incomplete chips")
    parser.add_argument("--no-clean", action="store_true", help="do not remove old generated .v files before writing")
    args = parser.parse_args()

    chips = discover_chips(args.input_dir, args.recursive)
    interfaces = {**BUILTINS, **chips}

    args.output_dir.mkdir(parents=True, exist_ok=True)
    if args.incomplete_output_dir:
        args.incomplete_output_dir.mkdir(parents=True, exist_ok=True)
    if not args.no_clean:
        clean_generated(args.output_dir, args.incomplete_output_dir)

    write_generated(args.output_dir / "Nand.v", NAND_VERILOG)

    for chip in sorted(chips.values(), key=lambda item: item.name):
        if not chip.complete:
            if args.incomplete_output_dir:
                write_generated(args.incomplete_output_dir / f"{chip.name}.v", emit_chip(chip, interfaces, blackbox=True))
            else:
                print(f"skip incomplete {chip.path}")
            continue
        write_generated(args.output_dir / f"{chip.name}.v", emit_chip(chip, interfaces))


if __name__ == "__main__":
    main()
