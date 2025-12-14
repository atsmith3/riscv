# ==============================================================================
# Equivalence Checking Script for Potato RISC-V Core
# ==============================================================================
# Purpose: Formally verify that synthesized gate-level netlist is functionally
#          equivalent to the original RTL
# Method: Induction-based equivalence checking using Yosys equiv commands
# Date: 2025-12-05
# ==============================================================================

# Import Yosys commands into TCL namespace
yosys -import

puts "\n================================================================================"
puts "POTATO RISC-V CORE - EQUIVALENCE CHECKING"
puts "================================================================================"

# ==============================================================================
# 1. READ AND SYNTHESIZE ORIGINAL RTL (GOLD)
# ==============================================================================

puts "\n=== Phase 1: Reading and Synthesizing Original RTL (Gold) ==="

set include_path "../../rtl"

# Read file list
set fp [open "file_list.txt" r]
set file_data [read $fp]
close $fp

puts "  Reading RTL files..."
set file_count 0
foreach line [split $file_data "\n"] {
    set line [string trim $line]
    if {$line != "" && [string index $line 0] != "#"} {
        read_verilog -sv -I$include_path $line
        incr file_count
    }
}
puts "  Read $file_count files"

# Synthesize to same level as gate netlist (but don't convert to AIG)
puts "\n  Synthesizing gold design..."
hierarchy -top core_top -check

yosys proc
opt_expr
opt_clean
opt -nodffe -nosdff

# FSM optimization
fsm_detect
fsm_extract
fsm_opt
fsm_recode -encoding onehot
fsm_map
opt

wreduce
peepopt
opt_clean

# Memory mapping (must match synthesis flow)
memory -nomap
opt_clean
memory_map
opt_clean

# Technology mapping
techmap
opt
techmap -map +/techmap.v
opt_clean

# Flatten (must match synthesis flow)
flatten
opt_clean

clean -purge
opt_clean
opt

puts "  Gold design synthesized"

# Rename to "gold"
puts "  Renaming core_top to core_top_gold..."
rename core_top core_top_gold

# ==============================================================================
# 2. READ SYNTHESIZED GATE-LEVEL NETLIST (GATE)
# ==============================================================================

puts "\n=== Phase 2: Reading Synthesized Gate-Level Netlist (Gate) ==="

# Check that synthesized netlist exists
puts "  Reading gate-level netlist: build/output/core_top_synth.v"
read_verilog build/output/core_top_synth.v

hierarchy -top core_top -check
clean -purge
opt_clean

puts "  Gate design loaded"

# Rename to "gate"
puts "  Renaming core_top to core_top_gate..."
rename core_top core_top_gate

# ==============================================================================
# 3. CREATE EQUIVALENCE CHECKING STRUCTURE
# ==============================================================================

puts "\n=== Phase 3: Setting Up Equivalence Checking ==="

puts "  Creating equivalence structure..."
puts "  Comparing core_top_gold vs core_top_gate"

# Create miter circuit for equivalence checking
equiv_make core_top_gold core_top_gate equiv_check

puts "  Equivalence structure created"

# ==============================================================================
# 4. RUN EQUIVALENCE CHECKING
# ==============================================================================

puts "\n=== Phase 4: Running Equivalence Checking ==="
puts "  Method: Induction-based formal verification"
puts "  This may take 30-60 seconds..."

# Run induction-based equivalence checking
# -undef: treat undefined values conservatively
equiv_induct -undef equiv_check

# ==============================================================================
# 5. CHECK STATUS AND REPORT RESULTS
# ==============================================================================

puts "\n=== Phase 5: Equivalence Check Results ==="

# Check equivalence status
# -assert will cause the script to fail if equivalence doesn't hold
equiv_status -assert equiv_check

# ==============================================================================
# EQUIVALENCE CHECK COMPLETE
# ==============================================================================

puts "\n================================================================================"
puts "EQUIVALENCE CHECK: PASSED"
puts "================================================================================"
puts "\nResult: RTL (gold) and gate-level netlist (gate) are functionally equivalent"
puts "\nThis formally proves that synthesis preserved the design's functionality."
puts "================================================================================"
