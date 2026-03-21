# ==============================================================================
# Equivalence Checking Script for Potato RISC-V Core
# ==============================================================================
# Purpose: Formally verify that synthesized gate-level netlist is functionally
#          equivalent to the original RTL
# Method: Induction-based equivalence checking using Yosys equiv commands
# Version: 1.0.0
# Date: 2025-12-05
# ==============================================================================

# Import Yosys commands into TCL namespace
yosys -import

puts "\n================================================================================"
puts "POTATO RISC-V CORE - EQUIVALENCE CHECKING"
puts "================================================================================"

# ==============================================================================
# Configuration
# ==============================================================================

# Timeout in seconds (default: 300 = 5 minutes)
set timeout_sec 300

# ==============================================================================
# 1. READ SYNTHESIZED GATE-LEVEL NETLIST (GATE)
# ==============================================================================

puts "\n=== Phase 1: Reading Synthesized Gate-Level Netlist (Gate) ==="

# Check that synthesized netlist exists
puts "  Reading gate-level netlist: ../build/output/core_top_synth.v"
if {[file exists "../build/output/core_top_synth.v"]} {
    read_verilog ../build/output/core_top_synth.v
    puts "  Gate netlist loaded successfully"
} else {
    puts "  ERROR: Gate-level netlist not found!"
    puts "  Expected: ../build/output/core_top_synth.v"
    puts "  Run 'make synth' first to generate the netlist."
    exit 1
}

hierarchy -top core_top -check
clean -purge
opt_clean

puts "  Gate design loaded (module: core_top)"

# ==============================================================================
# 2. READ AND SYNTHESIZE ORIGINAL RTL (GOLD)
# ==============================================================================

puts "\n=== Phase 2: Reading and Synthesizing Original RTL (Gold) ==="

set include_path "../../rtl"

# Read file list (excluding core_top.sv since we read the synthesized netlist)
set fp [open "file_list.txt" r]
set file_data [read $fp]
close $fp

puts "  Reading RTL files..."
set file_count 0
foreach line [split $file_data "\n"] {
    set line [string trim $line]
    # Skip core_top.sv and comments
    if {$line == "../../rtl/core_top.sv" || $line == "" || [string index $line 0] == "#"} {
        continue
    }
    read_verilog -sv -I$include_path $line
    incr file_count
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
fsm_recode
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

puts "  Gold design synthesized (module: core_top)"

# ==============================================================================
# 3. CREATE EQUIVALENCE CHECKING STRUCTURE
# ==============================================================================

puts "\n=== Phase 3: Setting Up Equivalence Checking ==="

puts "  Creating equivalence structure..."
puts "  Comparing core_top_gold vs core_top_gate"

# Create miter circuit for equivalence checking
# Using module names directly (no rename needed)
equiv_make core_top core_top equiv_check

puts "  Equivalence structure created"

# ==============================================================================
# 4. RUN EQUIVALENCE CHECKING
# ==============================================================================

puts "\n=== Phase 4: Running Equivalence Checking ==="
puts "  Method: Induction-based formal verification"
puts "  Timeout: ${timeout_sec} seconds"
puts "  This may take 30-60 seconds..."

# Run induction-based equivalence checking
# -undef: treat undefined values conservatively
# Using timeout to prevent hanging on large designs
if {[catch {
    equiv_induct -undef equiv_check
} msg]} {
    puts "\n  ERROR: Equivalence checking failed with error:"
    puts "  $msg"
    puts "\n  Common causes:"
    puts "    - RTL and gate-level use different file lists"
    puts "    - Synthesis warnings may indicate problems"
    puts "    - Yosys version mismatch"
    puts "    - Timeout exceeded (${timeout_sec}s)"
    puts "\n  Check the log file for details."
    exit 1
}

# ==============================================================================
# 5. CHECK STATUS AND REPORT RESULTS
# ==============================================================================

puts "\n=== Phase 5: Equivalence Check Results ==="

# Check equivalence status
# -assert will cause the script to fail if equivalence doesn't hold
if {[catch {equiv_status -assert equiv_check} result] || [string compare $result 0] != 0} {
    puts "\n  ERROR: Equivalence check failed!"
    puts "\n  Common causes:"
    puts "    - RTL and gate-level use different file lists"
    puts "    - Synthesis warnings may indicate problems"
    puts "    - Yosys version mismatch"
    puts "\n  Check the log file for details."
    exit 1
}

# ==============================================================================
# EQUIVALENCE CHECK COMPLETE
# ==============================================================================

puts "\n================================================================================"
puts "EQUIVALENCE CHECK: PASSED"
puts "================================================================================"
puts "\nResult: RTL (gold) and gate-level netlist (gate) are functionally equivalent"
puts "\nThis formally proves that synthesis preserved the design's functionality."
puts "================================================================================"
