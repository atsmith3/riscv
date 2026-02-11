# Vivado Emulation — Arty S7-50

FPGA build flow for the RISC-V 32I core (`core_top`) targeting the Digilent Arty S7-50 board (`xc7s50csga324-1`).

Uses Vivado **non-project mode** with checkpoint-based stages. Out-of-context synthesis is used to evaluate resource utilization and timing without pin assignments.

## Prerequisites

- Vivado (with Spartan-7 device support)
- `vivado` on `$PATH`
- GNU Make

## Quick Start

```bash
cd emulation/vivado/arty_s7_50

make all        # Full flow: lint → synth → opt → place → route → bitstream
make lint       # Just validate RTL syntax and hierarchy
make help       # Show all targets
```

## Build Targets

| Target | Description | Input | Output |
|---|---|---|---|
| `lint` | RTL elaboration — syntax, hierarchy, connectivity | RTL sources | `compile_order.rpt` |
| `synth` | Out-of-context synthesis | RTL sources | `post_synth.dcp` |
| `opt` | Logic optimization (`opt_design`) | `post_synth.dcp` | `post_opt.dcp` |
| `place` | Placement (`place_design`) | `post_opt.dcp` | `post_place.dcp` |
| `route` | Routing (`route_design`) | `post_place.dcp` | `post_route.dcp` |
| `bitstream` | Bitstream generation | `post_route.dcp` | `emu_top.bit` |
| `clean` | Remove all build artifacts | — | — |

`make all` chains every stage in order. Each stage after `lint` requires the `build/latest` symlink (created by `lint`).

## Build Directory Layout

Each `make lint` (or `make all`) invocation creates a timestamped build directory with a `build/latest` symlink for easy access. Subsequent stages write into the same directory via the symlink.

```
build/
├── latest -> 20260209_143022
└── 20260209_143022/
    ├── lint/
    │   ├── lint.log
    │   └── compile_order.rpt
    ├── synth/
    │   ├── synth.log
    │   ├── post_synth.dcp
    │   ├── utilization.rpt
    │   ├── timing_summary.rpt
    │   └── methodology.rpt
    ├── opt/
    │   ├── opt.log
    │   ├── post_opt.dcp
    │   ├── utilization.rpt
    │   └── timing_summary.rpt
    ├── place/
    │   ├── place.log
    │   ├── post_place.dcp
    │   ├── utilization.rpt
    │   ├── timing_summary.rpt
    │   └── clock_utilization.rpt
    ├── route/
    │   ├── route.log
    │   ├── post_route.dcp
    │   ├── utilization.rpt
    │   ├── timing_summary.rpt
    │   ├── route_status.rpt
    │   └── power.rpt
    └── bitstream/
        ├── bitstream.log
        └── emu_top.bit
```

## Opening Checkpoints in the GUI

Any `.dcp` file can be opened directly in Vivado for interactive inspection:

```bash
vivado build/latest/synth/post_synth.dcp
vivado build/latest/route/post_route.dcp
```

## Architecture

### Emulation Wrapper (`emu_top.sv`)

`emu_top` wraps `core_top` for FPGA targeting:

- Maps the board's 12 MHz clock (`CLK12MHZ`) to `core_top.clk`
- Ties `rst_n` to `1'b1` (reset inactive)
- Exposes all memory interface ports and `pc` at the top level for OOC synthesis

### RTL Compilation Order

Source files are read in dependency order. `datatypes.sv` is not read directly — it is pulled in via `` `include `` directives, with the include path set to `rtl/`.

### Constraints

The XDC file (`xdc/Arty-S7-50-Master.xdc`) defines the 12 MHz clock on pin F14 with an 83.333 ns period. All other board I/O constraints are commented out.
