# Vivado Emulation — Arty S7-50

FPGA build flow for the RISC-V 32I core (`core_top`) targeting the Digilent Arty S7-50 board (`xc7s50csga324-1`).

Uses Vivado **non-project mode** with checkpoint-based stages. The design is self-contained with on-chip BRAM, button-driven reset, and LED-based pass/fail reporting.

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
| `hex` | Convert test `.ini` to `$readmemh` format | `test/<name>/<name>.ini` | `build/<name>.hex` |
| `lint` | RTL elaboration — syntax, hierarchy, connectivity | RTL sources | `compile_order.rpt` |
| `synth` | Synthesis | RTL sources | `post_synth.dcp` |
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

### Sub-blocks

- **Clock path** — `CLK12MHZ` passes through an `IBUF` → `BUFG` chain to produce `clk`.
- **Reset** — `btn[0]` (active-high on the Arty S7) is synchronized with a 2-FF chain and inverted to produce `rst_n`.
- **core_top (DUT)** — The RISC-V 32I core under test, connected to memory via a simple read/write interface.
- **bram_memory** — 16 KB (4096 × 32-bit words) BRAM initialized with `$readmemh`. Provides 1-cycle read latency and byte-enable writes. The hex file is generated from a test `.ini` file by `scripts/ini2hex.py` (the `make hex` target).
- **Magic address detector** — A write to any address matching `0xDEAD_xxxx` captures the test result: `wdata == 1` sets `pass_flag`, anything else sets `fail_flag`.
- **LED mapping** — `led[0]` = pass, `led[1]` = fail, `led[3:2]` = `pc[13:12]` (activity indicator).

### RTL Compilation Order

Source files are read in dependency order. `datatypes.sv` is not read directly — it is pulled in via `` `include `` directives, with the include path set to `rtl/`.

### Constraints

The XDC file (`xdc/Arty-S7-50-Master.xdc`) defines the 12 MHz clock on pin F14 with an 83.333 ns period. LED and button pin assignments are active; unused board I/O constraints are commented out.
