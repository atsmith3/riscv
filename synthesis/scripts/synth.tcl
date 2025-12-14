# ==============================================================================
# Yosys Synthesis Script for Potato RISC-V Core
# ==============================================================================
# Target: AIGER format for formal verification and simulation
# Design: Multi-cycle in-order RISC-V 32I processor
# Date: 2025-12-05
# ==============================================================================

# Import Yosys commands into TCL namespace
yosys -import

# ==============================================================================
# 1. READ RTL SOURCES
# ==============================================================================

puts "\n================================================================================"
puts "POTATO RISC-V CORE - YOSYS SYNTHESIS TO AIGER"
puts "================================================================================"

# Set include path for SystemVerilog includes
set include_path "../../rtl"

# Read all RTL files with SystemVerilog support
# Note: All files must be read in a single read_verilog command
#       to avoid duplicate enum definitions from includes
puts "\n=== Phase 1: Reading RTL Sources with SystemVerilog Support ==="

# Read file list (contains properly ordered files)
set fp [open "file_list.txt" r]
set file_data [read $fp]
close $fp

# Build list of all RTL files
set rtl_files [list]
foreach line [split $file_data "\n"] {
    set line [string trim $line]
    # Skip empty lines and comments
    if {$line != "" && [string index $line 0] != "#"} {
        lappend rtl_files $line
    }
}

puts "  Reading [llength $rtl_files] RTL files..."
foreach file $rtl_files {
    puts "    - $file"
}

# Read all files in a single command to handle includes correctly
# Use -defer to delay compilation until hierarchy command
read_verilog -sv -defer -I$include_path {*}$rtl_files

puts "  Total files read: [llength $rtl_files]"

# ==============================================================================
# 2. ELABORATE AND CHECK DESIGN
# ==============================================================================

puts "\n=== Phase 2: Elaboration and Hierarchy Check ==="

# Set top module
hierarchy -top core_top -check

# Show design hierarchy
puts "\n  Design Hierarchy:"
hierarchy -check

puts "\n  Initial Statistics:"
stat

# ==============================================================================
# 3. SYNTHESIS - HIGH LEVEL OPTIMIZATION
# ==============================================================================

puts "\n=== Phase 3: High-Level Synthesis and Optimization ==="

# Process behavioral constructs (always blocks, etc.)
puts "  Processing behavioral constructs..."
yosys proc

# Optimize expressions
puts "  Optimizing expressions..."
opt_expr

# Clean up unused signals
opt_clean

# Run optimization (handle DFF, FSM, etc.)
puts "  Running general optimizations..."
opt -nodffe -nosdff

# ==============================================================================
# 4. FSM OPTIMIZATION (CRITICAL FOR CONTROL UNIT)
# ==============================================================================

puts "\n=== Phase 4: FSM Optimization (Control Unit) ==="

# Extract and optimize the FSM in control module
puts "  Detecting FSMs..."
fsm_detect

puts "  Extracting FSM structure..."
fsm_extract

puts "  Optimizing FSM..."
fsm_opt

# Encode FSM states (automatic encoding selection)
puts "  Encoding FSM states..."
fsm_recode

# Convert FSM to logic
puts "  Mapping FSM to logic gates..."
fsm_map

# General optimization after FSM processing
opt

# ==============================================================================
# 5. WORD SIZE REDUCTION AND PEEPHOLE OPTIMIZATION
# ==============================================================================

puts "\n=== Phase 5: Additional Optimizations ==="

# Reduce word sizes where possible
puts "  Reducing word sizes..."
wreduce

# Peephole optimizations
puts "  Running peephole optimizations..."
peepopt
opt_clean

# ==============================================================================
# 6. MEMORY MAPPING
# ==============================================================================

puts "\n=== Phase 6: Memory Processing and Mapping ==="

# Process memories (register file and CSR file)
# -nomap: don't map to target memory yet, keep abstract
puts "  Processing memory structures..."
memory -nomap
opt_clean

# Map memories to registers and logic
# This converts the 32x32 register file to 1024 flip-flops
# and maps the CSR file counters to flip-flops
puts "  Mapping memories to flip-flops and logic..."
memory_map
opt_clean

# ==============================================================================
# 7. TECHNOLOGY MAPPING TO GATES
# ==============================================================================

puts "\n=== Phase 7: Technology Mapping to Generic Gates ==="

# Map high-level logic to technology gates
puts "  Mapping to generic gates..."
techmap
opt

# Map to simple logic gates
puts "  Mapping to basic logic primitives..."
techmap -map +/techmap.v
opt_clean

# ==============================================================================
# 8. FLATTEN DESIGN
# ==============================================================================

puts "\n=== Phase 8: Flattening Design Hierarchy ==="
puts "  (AIGER requires completely flat design)"

# AIGER requires completely flat design - no hierarchy
flatten
opt_clean

# ==============================================================================
# 9. TECHNOLOGY MAPPING TO STANDARD GATES
# ==============================================================================

puts "\n=== Phase 9: Technology Mapping to Standard Gates ==="

# Clean and optimize before technology mapping
clean -purge
opt_clean
opt

# Map to standard library cells (AND, OR, NOT, NAND, NOR, XOR, MUX, DFF variants)
puts "  Mapping to standard gate library..."
techmap

# Optimize at gate level
opt

# Final cleanup
opt_clean

# ==============================================================================
# 10. STATISTICS AND VALIDATION
# ==============================================================================

puts "\n=== Phase 10: Design Statistics and Validation ==="

puts "\n  Final Design Statistics:"
stat

puts "\n  Design Check (errors/warnings):"
check

# Show cell types (should be only $_AND_, $_NOT_, $_DFF_*, and I/O)
puts "\n  Cell Types in Final Design:"
select -module core_top
stat

# ==============================================================================
# 11. WRITE GATE-LEVEL NETLIST
# ==============================================================================

puts "\n=== Phase 11: Writing Gate-Level Netlist ==="

# Write Verilog netlist (primary output)
puts "  Writing gate-level Verilog netlist..."
yosys write_verilog -noattr ../build/output/core_top_synth.v

# Write JSON for tool interoperability
puts "  Writing JSON netlist..."
yosys write_json ../build/output/core_top_synth.json

# Write BLIF for legacy tools
puts "  Writing BLIF netlist..."
yosys write_blif ../build/output/core_top_synth.blif

# ==============================================================================
# 12. GENERATE REPORTS
# ==============================================================================

puts "\n=== Phase 12: Generating Reports ==="

# Statistics report
puts "  Generating statistics report..."
tee -a ../build/reports/statistics.txt stat

# Design check report
puts "  Generating design check report..."
tee -a ../build/reports/check.txt check

# ==============================================================================
# SYNTHESIS COMPLETE
# ==============================================================================

puts "\n================================================================================"
puts "SYNTHESIS COMPLETE"
puts "================================================================================"
puts "\nOutput Files:"
puts "  - Verilog netlist:    ../build/output/core_top_synth.v"
puts "  - JSON netlist:       ../build/output/core_top_synth.json"
puts "  - BLIF netlist:       ../build/output/core_top_synth.blif"
puts "\nReports:"
puts "  - Statistics:         ../build/reports/statistics.txt"
puts "  - Design check:       ../build/reports/check.txt"
puts "\n================================================================================"
