# Potato RISC-V Core - Gate-Level Synthesis

This directory contains the synthesis infrastructure for converting the Potato RISC-V RV32I core from SystemVerilog RTL to gate-level netlists suitable for ASIC implementation targeting the GlobalFoundries 180nm PDK.

## Table of Contents

1. [Quick Start](#quick-start)
2. [Overview](#overview)
3. [Directory Structure](#directory-structure)
4. [Build Targets](#build-targets)
5. [Interface Documentation](#interface-documentation)
6. [Expected Statistics](#expected-statistics)
7. [Synthesis Flow Details](#synthesis-flow-details)
8. [Equivalence Checking](#equivalence-checking)
9. [Output Files](#output-files)
10. [Integration Guide](#integration-guide)
11. [Troubleshooting](#troubleshooting)
12. [Technical Notes](#technical-notes)

---

## Quick Start

### Prerequisites

- **Yosys 0.49+** - Open synthesis suite ([https://github.com/YosysHQ/yosys](https://github.com/YosysHQ/yosys))

### Basic Usage

```bash
cd synthesis
make all
```

This runs the complete synthesis flow:
1. Synthesis (RTL → gates) - ~60-120 seconds
2. Validation (check netlists) - <1 second
3. Equivalence checking (formal proof) - ~30-60 seconds
4. Report generation - ~1 second

**Total runtime**: ~2-3 minutes

### Output Files

After successful synthesis, you'll find:

```
synthesis/build/output/
├── core_top_synth.v       # Gate-level Verilog netlist (~700 KB)
├── core_top_synth.json    # JSON netlist for tools (~6 MB)
└── core_top_synth.blif    # BLIF format (~2 MB)
```

---

## Overview

### Purpose

The synthesis flow converts the high-level SystemVerilog RTL into a gate-level netlist using standard logic cells. This netlist is suitable for:

- **ASIC implementation** - Mapping to PDK standard cells (targeting GF180)
- **Formal verification** - Equivalence checking, property proving
- **Timing analysis** - Static timing analysis with cell delays
- **Place and route** - Backend physical design flow

### Gate Library

The synthesis produces a netlist using Yosys standard gate primitives:
- **Logic gates** - $_AND_, $_OR_, $_NOT_, $_NAND_, $_NOR_, $_XOR_
- **Multiplexers** - $_MUX_ (2:1 select)
- **Flip-flops** - $_DFF_P_ (basic), $_SDFF_PN0_ (sync reset), $_DFFE_PP_ (enable), and variants

All complex RTL constructs (ALU operations, multiplexers, decoders) are mapped to these primitives, which can later be mapped to PDK cells.

### Output Formats

This synthesis flow generates three formats:

1. **Verilog Netlist (.v)** - Gate-level Verilog (primary output)
   - Best for: Traditional EDA flows, PDK mapping, debugging
   - Size: ~700 KB
   - Contains: $_* gate primitives and flip-flops

2. **JSON Netlist (.json)** - Yosys JSON interchange format
   - Best for: Tool integration, custom analysis
   - Size: ~6 MB
   - Contains: Complete design graph with metadata

3. **BLIF (.blif)** - Berkeley Logic Interchange Format
   - Best for: Legacy EDA tools, ABC integration
   - Size: ~2 MB

---

## Directory Structure

```
synthesis/
├── README.md                    # This file
├── Makefile                     # Build automation
├── scripts/
│   ├── synth.tcl               # Main Yosys synthesis script
│   ├── equiv_check.tcl         # Equivalence checking script
│   └── file_list.txt           # RTL files in dependency order
├── build/                       # Generated outputs (gitignored)
│   ├── logs/                   # Timestamped synthesis logs
│   ├── reports/                # Statistics and summary reports
│   └── output/                 # Gate-level netlists
└── constraints/
    └── synth_constraints.txt   # Synthesis configuration notes
```

---

## Build Targets

### `make all` (default)

Runs the complete synthesis flow: synth → validate → equiv → reports

**Runtime**: 2-3 minutes

**Use when**: Running synthesis for the first time or after RTL changes

### `make synth`

Runs Yosys synthesis to generate gate-level netlists.

**Runtime**: 60-120 seconds

**Outputs**:
- Gate-level Verilog netlist (core_top_synth.v)
- JSON netlist (core_top_synth.json)
- BLIF netlist (core_top_synth.blif)

**Log**: `build/logs/synthesis_YYYYMMDD_HHMMSS.log`

### `make validate`

Validates gate-level netlist structure.

**Runtime**: <1 second

**Checks**:
- Verilog netlist exists and is non-empty
- JSON netlist exists
- BLIF netlist exists
- Synthesized logic present in Verilog

### `make equiv`

Runs formal equivalence checking to prove RTL ≡ gate-level netlist.

**Runtime**: 30-60 seconds

**Method**: Induction-based formal verification

**Result**: PASS/FAIL - Any failure indicates a synthesis bug

**Log**: `build/logs/equiv_check_YYYYMMDD_HHMMSS.log`

### `make reports`

Generates human-readable synthesis summary.

**Output**: `build/reports/synthesis_summary.txt`

**Contents**:
- File sizes and locations
- Interface summary
- Timestamp

### `make clean`

Removes all build artifacts while preserving directory structure.

**Use when**: Starting fresh or cleaning up before committing

### `make help`

Displays usage information, targets, and examples.

---

## Interface Documentation

The core's I/O interface is preserved through synthesis and becomes the AIGER primary I/O.

### Inputs (35 bits total)

| Signal | Width | Description |
|--------|-------|-------------|
| `clk` | 1 | System clock (becomes latch clock in AIGER) |
| `rst_n` | 1 | Active-low asynchronous reset |
| `mem_rdata` | 32 | Memory read data bus |
| `mem_resp` | 1 | Memory response ready signal |

### Outputs (102 bits total)

| Signal | Width | Description |
|--------|-------|-------------|
| `mem_wdata` | 32 | Memory write data bus |
| `mem_addr` | 32 | Memory address (word-aligned) |
| `mem_read` | 1 | Memory read enable |
| `mem_write` | 1 | Memory write enable |
| `mem_be` | 4 | Byte enable signals |
| `pc` | 32 | Program counter (for observability) |

### Memory Interface Protocol

**Read Sequence**:
1. Core asserts `mem_read`, sets `mem_addr`
2. Core waits for `mem_resp=1`
3. Memory provides data on `mem_rdata`, asserts `mem_resp`
4. Core captures data

**Write Sequence**:
1. Core asserts `mem_write`, sets `mem_addr`, `mem_wdata`, `mem_be`
2. Core waits for `mem_resp=1`
3. Memory writes data with byte enables, asserts `mem_resp`
4. Core proceeds

---

## Expected Statistics

### Total Cells: ~9,600-9,800

The synthesis produces a compact gate-level design with mixed cell types:

| Cell Type | Count | Description |
|-----------|-------|-------------|
| $_MUX_ | ~4,300 | 2:1 multiplexers (datapath, register file reads) |
| $_AND_ | ~1,700 | AND gates (ALU, decoder, control logic) |
| $_OR_ | ~1,500 | OR gates (combining signals, branch logic) |
| $_DFFE_PP_ | ~1,024 | DFFs with enable (register file writes) |
| $_XOR_ | ~300 | XOR gates (ALU, comparisons) |
| $_NOT_ | ~260 | Inverters (negation, active-low signals) |
| $_DFFE_PN0P_ | ~191 | DFFs with enable and reset to 0 |
| $_DFF_PN0_ | ~128 | DFFs with reset to 0 (program registers) |
| $_SDFFE_PN0P_ | ~127 | DFFs with sync reset+enable |
| $_SDFF_PN0_ | ~6 | DFFs with sync reset |
| Other FF variants | ~3 | Misc DFF types |
| **Total** | **~9,680** | Actual synthesis result |

**Why fewer cells than AIGER?** The AIGER flow decomposed everything to AND/NOT primitives. Standard gate synthesis uses richer cells (OR, XOR, MUX) that capture more functionality per cell.

### Flip-Flops: ~1,450-1,480

| Component | Count | Description |
|-----------|-------|-------------|
| Register file | 1024 | 32 registers × 32 bits (mostly $_DFFE_PP_) |
| CSR counters | ~300 | 64-bit counters with increment logic |
| Program registers | 128 | PC, IR, MAR, MDR |
| FSM state | ~40 | One-hot encoded control FSM |
| **Total** | **~1,479** | Sum of all DFF variants |

### File Sizes

| File | Expected Size | Notes |
|------|---------------|-------|
| Verilog netlist (.v) | ~700 KB | Gate-level, human-readable |
| JSON netlist (.json) | ~6 MB | Complete design graph with metadata |
| BLIF netlist (.blif) | ~2 MB | Berkeley Logic Interchange Format |
| Synthesis log | 1-2 MB | Yosys output with statistics |

---

## Synthesis Flow Details

The synthesis script (`scripts/synth.tcl`) implements a 12-phase flow:

### Phase 1: Read RTL Sources

- Read all SystemVerilog files with `-sv` flag
- Set include path to `../rtl` for `\`include` directives
- Process files in dependency order from `file_list.txt`
- **Critical**: `datatypes.sv` must be first (defines all enums/typedefs)

### Phase 2: Elaborate and Check Design

- Set top module to `core_top`
- Check hierarchy for missing modules
- Generate initial statistics

### Phase 3: High-Level Synthesis

- `proc` - Process behavioral constructs (always blocks)
- `opt_expr` - Optimize expressions
- `opt_clean` - Remove unused signals
- `opt` - General optimization pass

### Phase 4: FSM Optimization

**Critical for control unit synthesis**:

1. `fsm_detect` - Identify FSM in control module
2. `fsm_extract` - Extract FSM structure
3. `fsm_opt` - Optimize FSM (reduce states, remove unreachable)
4. `fsm_recode -encoding onehot` - **One-hot encoding**
   - Creates 36 flip-flops for 36-state FSM
   - Simpler next-state logic vs binary encoding
   - Better for formal verification
5. `fsm_map` - Convert FSM to logic gates

### Phase 5: Word Size Reduction and Peephole Optimization

- `wreduce` - Reduce word sizes where possible
- `peepopt` - Peephole optimizations (pattern matching)
- `opt_clean` - Clean up

### Phase 6: Memory Processing and Mapping

**Register File** (32×32 bits):
1. `memory -nomap` - Process abstractly
2. `memory_map` - Map to 1024 individual flip-flops
   - Creates separate FF for each bit
   - Read ports become mux trees
   - Write port becomes enable logic

**CSR File** (counters and machine CSRs):
- Similar mapping to flip-flops
- Counter increment logic mapped to adders

### Phase 7: Technology Mapping

- `techmap` - Map high-level constructs to gates
- `techmap -map +/techmap.v` - Map to basic logic primitives
- Multiple passes for complete reduction

### Phase 8: Flatten Design

- `flatten` - Remove all hierarchy
- All module boundaries disappear
- Creates single flat netlist for final optimization

### Phase 9: Technology Mapping to Standard Gates

**Gate library mapping**:

1. `clean -purge` - Final cleanup
2. `opt_clean` and `opt` - Optimize before mapping
3. `techmap` - **Map to standard gate library**
   - Multiplexers → $_MUX_ cells
   - AND/OR/NOT/NAND/NOR/XOR → Corresponding $_ cells
   - Arithmetic → Gate networks
   - Preserves DFF variants ($_DFFE_*, $_SDFF_*, etc.)

**Result**: Rich gate library suitable for PDK mapping

### Phase 10: Statistics and Validation

- `stat` - Generate statistics
- `check` - Validate design (no errors)
- Show cell types: $_AND_, $_OR_, $_NOT_, $_XOR_, $_MUX_, $_DFF_*, etc.

### Phase 11: Write Gate-Level Netlists

1. **Verilog netlist** (primary output):
   ```tcl
   write_verilog -noattr build/output/core_top_synth.v
   ```
   - Gate-level Verilog with $_ primitives
   - Human-readable format
   - Best for: Traditional EDA flows, PDK mapping

2. **JSON netlist**:
   ```tcl
   write_json build/output/core_top_synth.json
   ```
   - Complete design graph with metadata
   - Best for: Custom tools, analysis scripts

3. **BLIF netlist**:
   ```tcl
   write_blif build/output/core_top_synth.blif
   ```
   - Berkeley Logic Interchange Format
   - Best for: ABC tools, legacy EDA flows

### Phase 12: Generate Reports

- Statistics report: `build/reports/statistics.txt`
- Design check report: `build/reports/check.txt`

---

## Equivalence Checking

Formal verification that synthesis preserved functionality.

### Purpose

Prove mathematically that:
```
RTL behavior ≡ Gate-level netlist behavior
```

For all possible inputs and all possible states, the outputs are identical.

### Method: Induction-Based Equivalence

The script (`scripts/equiv_check.tcl`) uses induction-based formal verification:

1. **Read original RTL** - Synthesize to gate level (but not AIG)
2. **Read synthesized netlist** - Load gate-level Verilog
3. **Create equivalence structure** - Miter circuit comparing outputs
4. **Run induction** - Formally prove equivalence using SAT solver
5. **Assert success** - Fail build if equivalence doesn't hold

### Interpreting Results

**PASS**: RTL and gate-level are formally equivalent
- Synthesis preserved all functionality
- Safe to use AIGER for verification

**FAIL**: Equivalence violation detected
- Synthesis bug (very rare with stable Yosys)
- OR mismatch in RTL file list
- Check `build/logs/equiv_check_*.log` for details

### Runtime

- Typical: 30-60 seconds
- Depends on design size and SAT solver performance
- One-time proof (doesn't need to run repeatedly)

---

## Output Files

### core_top_synth.v (Verilog Netlist)

**Format**: Gate-level Verilog with Yosys $_ primitives

**Size**: ~700 KB

**Cell Types**: $_AND_, $_OR_, $_NOT_, $_XOR_, $_MUX_, $_DFF_P_, $_DFFE_PP_, $_SDFF_PN0_, etc.

**Structure**:
```verilog
module core_top(clk, rst_n, mem_rdata, mem_resp, ...);
  wire _00001_, _00002_, ...;

  $_AND_ _1234_ (.A(_00001_), .B(_00002_), .Y(_00003_));
  $_MUX_ _1235_ (.A(_00004_), .B(_00005_), .S(_00006_), .Y(_00007_));
  $_DFFE_PP_ _1236_ (.D(_00008_), .C(clk), .E(_00009_), .Q(_00010_));
  ...
endmodule
```

**Use Cases**:
- Input for PDK mapping (via ABC or similar tools)
- Traditional EDA tool flows
- Debugging synthesis
- Understanding gate-level structure

### core_top_synth.json (JSON Netlist)

**Format**: JSON format with complete design graph

**Size**: ~6 MB

**Contents**:
- Module hierarchy (flattened to single module)
- Cell instances with types and connections
- Net definitions
- Port declarations
- Design metadata

**Use Cases**:
- Custom analysis scripts
- Tool integration (e.g., visualization tools)
- Automated design analysis
- Extracting design metrics

### core_top_synth.blif (BLIF Netlist)

**Format**: Berkeley Logic Interchange Format

**Size**: ~2 MB

**Use Cases**:
- ABC synthesis and optimization
- Legacy EDA tools that accept BLIF
- Alternative interchange format

---

## Integration Guide

### Future Work: GF180 PDK Mapping

The current gate-level netlist uses Yosys $_ primitives. For ASIC fabrication with the GlobalFoundries 180nm PDK, additional steps are required:

**1. Obtain PDK Liberty Files**

Download GF180 PDK from: https://github.com/google/gf180mcu-pdk

Required files:
- Liberty timing files (.lib) for each corner (typical, fast, slow)
- LEF physical layout files (.lef)
- Technology files for tools (e.g., .tf for Cadence)

**2. Map to PDK Standard Cells (via ABC)**

```bash
# Load gate-level netlist
yosys
yosys> read_verilog build/output/core_top_synth.v

# Map to GF180 standard cells using ABC
yosys> abc -liberty /path/to/gf180_tt_025C_1v80.lib

# Write mapped netlist
yosys> write_verilog -noattr build/output/core_top_gf180.v
```

This maps:
- $_AND_ → gf180mcu_fd_sc_mcu7t5v0__and2_1
- $_OR_ → gf180mcu_fd_sc_mcu7t5v0__or2_1
- $_DFF_P_ → gf180mcu_fd_sc_mcu7t5v0__dffq_1
- $_MUX_ → gf180mcu_fd_sc_mcu7t5v0__mux2_1
- etc.

**3. Add Timing Constraints**

Create SDC (Synopsys Design Constraints) file:
```tcl
# Clock definition
create_clock -name clk -period 100.0 [get_ports clk]

# Input delays
set_input_delay -clock clk -max 10.0 [all_inputs]

# Output delays
set_output_delay -clock clk -max 10.0 [all_outputs]

# Reset timing
set_false_path -from [get_ports rst_n]
```

**4. Place and Route (via OpenROAD)**

```bash
# Use OpenROAD Flow Scripts (ORFS)
# https://github.com/The-OpenROAD-Project/OpenROAD-flow-scripts

make DESIGN_CONFIG=./designs/gf180/potato_core/config.mk
```

This performs:
- Floorplanning
- Placement
- Clock tree synthesis
- Routing
- Timing optimization

**5. Final Output: GDS-II**

After place and route, you'll have:
- `core_top.gds` - Final layout for fabrication
- Timing reports (setup/hold analysis)
- Power analysis
- DRC/LVS reports

### Using with ABC for Optimization

[ABC](https://github.com/berkeley-abc/abc) can optimize the gate-level netlist before PDK mapping:

```bash
abc
abc> read_blif synthesis/build/output/core_top_synth.blif
abc> print_stats
abc> strash      # Convert to AIG for optimization
abc> refactor    # Refactoring
abc> balance     # Delay balancing
abc> print_stats # Check results
```

### JSON Netlist Analysis

Use the JSON output for custom analysis:

```python
import json

with open('build/output/core_top_synth.json') as f:
    design = json.load(f)

# Extract statistics
module = design['modules']['core_top']
cells = module['cells']

# Count cell types
from collections import Counter
cell_types = Counter(cell['type'] for cell in cells.values())
print(cell_types)

# Analyze connectivity
for net_name, net_data in module['netnames'].items():
    # Process net connections
    pass
```

---

## Troubleshooting

### Synthesis Fails with "ERROR: Module not found"

**Cause**: Files read in wrong order or missing from `file_list.txt`

**Solution**:
- Ensure `datatypes.sv` is first in `scripts/file_list.txt`
- Check that all module dependencies are listed before modules that use them
- Verify all files exist at specified paths

### "Warning: Wire has undriven bits"

**Usually safe**: Yosys warns about unused signals or ports

**Check**: If the warning is for critical signals, review RTL

**Suppress**: These warnings don't prevent netlist generation

### Unexpected Cell Counts

**Too few flip-flops** (< 1000):
- Check that register file and CSRs synthesized correctly
- Review synthesis log for memory mapping warnings
- Ensure `memory_map` pass ran successfully

**Too few logic gates** (< 1000):
- Check that all logic was included
- Review file list for missing modules
- Look for "optimized away" warnings
- Verify all RTL files were read correctly

### Equivalence Check Fails

**Rare but serious**:
- Review `build/logs/equiv_check_*.log`
- Check that same file list used for both RTL and gate-level
- Verify Yosys version (0.49+ required)
- Report issue if using correct setup

### Yosys Not Found

**Error**: `/home/andrew/software/yosys/yosys/yosys: No such file or directory`

**Solution**:
1. Install Yosys from [https://github.com/YosysHQ/yosys](https://github.com/YosysHQ/yosys)
2. Update `YOSYS` variable in `Makefile` to correct path
3. Or add Yosys to PATH and change to `YOSYS := yosys`

### Synthesis Very Slow (> 5 minutes)

**Normal for first run**: JIT compilation and optimization

**Check**:
- System resources (RAM, CPU)
- Yosys version (newer versions are faster)
- Use `-O0` flag to disable aggressive optimization (already in script)

---

## Technical Notes

### SystemVerilog Feature Handling

Yosys 0.49+ natively handles SystemVerilog features used in this design:

**Enums** (11 total in `datatypes.sv`):
- Automatically converted to bit vectors
- Enum values become parameters
- No manual conversion needed

**Typedefs**:
- Resolved during elaboration
- No impact on synthesis

**always_comb / always_ff**:
- Synthesized to correct logic types
- `always_comb` → combinational
- `always_ff` → sequential (with clock)

**Include directives**:
- Handled with `-I../rtl` flag
- Resolves `\`include "datatypes.sv"`

**No preprocessing needed**: Direct SystemVerilog synthesis

### File Ordering Requirements

**Critical Rule**: `datatypes.sv` must be first

**Reason**: All other files depend on enum and typedef definitions

**File List Order** (`scripts/file_list.txt`):
1. Type definitions (datatypes.sv)
2. Leaf modules (no dependencies)
3. Mid-level modules (depend on leaves)
4. Control hierarchy
5. Top level (depends on everything)

**Violation**: "Unknown type" or "Unknown enum" errors

### Flatten Requirement

**Yosys `flatten` command**: Removes all module boundaries

**Result**: Single flat netlist with all logic

**Why flatten?**
- Simplifies gate-level optimization
- Enables cross-module optimizations
- Standard practice for ASIC synthesis
- Required for some optimization passes

**Impact**:
- All signals have flat names: `module.submodule.signal`
- Module hierarchy removed (single `core_top` module)
- Can complicate debugging (but still readable)

### Signal Naming in Gate-Level Netlist

**Internal wires**: Generated names like `_00001_`, `_00002_`, etc.

**Sequential logic**: May preserve some RTL signal names in DFF instances

**Debugging**: Use synthesis log to correlate gates back to RTL
- Yosys prints transformations during synthesis
- Cross-reference with RTL source
- JSON netlist contains more metadata for analysis

### One-Hot FSM Encoding

**Configuration**: `fsm_recode -encoding onehot`

**Trade-off**:
- **More flip-flops**: 36 FFs for 36-state FSM (vs ~6 for binary)
- **Simpler logic**: One FF per state, simple next-state
- **Better for formal**: Easier to prove properties
- **Faster synthesis**: Less optimization needed

**Alternative**: Binary encoding (`-encoding binary`)
- Fewer FFs (~6 for 36 states)
- More complex next-state logic
- Harder formal verification

**Choice**: One-hot preferred for formal verification focus

### Memory Mapping Strategy

**Register File** (32×32 bits):

**Abstract representation**:
```systemverilog
reg [31:0] data[31:0];  // 32-word array
```

**After `memory_map`**:
```
data[0][0], data[0][1], ..., data[0][31]  // Register 0
data[1][0], data[1][1], ..., data[1][31]  // Register 1
...
data[31][0], ..., data[31][31]  // Register 31
```

**Result**: 1024 individual flip-flops

**Read ports**: Become 1024:1 multiplexers

**Write port**: Becomes enable logic for each FF

**Performance**: Trade memory compactness for explicit logic

---

## References

- [Yosys Manual](https://yosyshq.readthedocs.io/)
- [ABC System](https://github.com/berkeley-abc/abc)
- [GlobalFoundries 180nm PDK](https://github.com/google/gf180mcu-pdk)
- [OpenROAD Flow Scripts](https://github.com/The-OpenROAD-Project/OpenROAD-flow-scripts)
- [Main Potato RISC-V Documentation](../README.md)

---

## License

This synthesis infrastructure is part of the Potato RISC-V core project.
