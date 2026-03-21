# ==============================================================================
# GF180 PDK Technology Mapping Script
# Maps Yosys gate primitives to GF180 standard cells
# ==============================================================================
# Usage: yosys -c pdk_map.tcl
# Version: 1.1.0 - Enhanced with multi-corner mapping and timing optimization
# Date: 2026-03-20
# ==============================================================================

yosys -import

# ==============================================================================
# Configuration
# ==============================================================================

# Target clock period (picoseconds)
# Adjust based on your target frequency:
#   - 100 MHz = 10000 (10ns period)
#   -  50 MHz = 20000 (20ns period)
#   - 200 MHz = 5000  (5ns period)
set -clock_period 10000

# Enable timing-aware optimization passes
set timing_optimization 1

# Enable area optimization passes
set area_optimization 1

# ==============================================================================
# 1. READ GATE-LEVEL NETLIST
# ==============================================================================

puts "\n================================================================================"
puts "GF180 PDK TECHNOLOGY MAPPING"
puts "================================================================================"

puts "\n=== Phase 1: Reading Gate-Level Netlist ==="

# Read from JSON format to preserve internal cell types
read_json ../build/output/core_top_synth.json

puts "\n  Initial Statistics (Yosys primitives):"
stat

# ==============================================================================
# 2. MAP TO GF180 STANDARD CELLS USING ABC
# ==============================================================================

puts "\n=== Phase 2: Mapping to GF180 Standard Cells ==="

# Check if there's a concatenated Liberty file or individual files
if {[file exists "gf180mcu_fd_sc_mcu9t5v0__tt_025C_3v30.lib"]} {
    # Use the fixed concatenated typical corner file
    set liberty_file "gf180mcu_fd_sc_mcu9t5v0__tt_025C_3v30.lib"
    set corner_name "typical"
} elseif {[file exists "gf180mcu_fd_sc_mcu9t5v0__tt_025C_1v80.lib"]} {
    # Fallback to fast corner
    set liberty_file "gf180mcu_fd_sc_mcu9t5v0__tt_025C_1v80.lib"
    set corner_name "fast"
} elseif {[file exists "gf180mcu_fd_sc_mcu9t5v0__ss_125C_1v62.lib"]} {
    # Fallback to slow corner
    set liberty_file "gf180mcu_fd_sc_mcu9t5v0__ss_125C_1v62.lib"
    set corner_name "slow"
} else {
    puts "ERROR: No Liberty file found!"
    puts "Required Liberty files:"
    puts "  - gf180mcu_fd_sc_mcu9t5v0__tt_025C_3v30.lib (typical)"
    puts "  - gf180mcu_fd_sc_mcu9t5v0__tt_025C_1v80.lib (fast)"
    puts "  - gf180mcu_fd_sc_mcu9t5v0__ss_125C_1v62.lib (slow)"
    puts ""
    puts "Download from: https://github.com/google/gf180mcu-pdk"
    exit 1
}

puts "  Using Liberty file: $liberty_file (corner: $corner_name)"

# Verify the liberty file is readable
if {[file size $liberty_file] == 0} {
    puts "ERROR: Liberty file is empty!"
    puts "File: $liberty_file"
    exit 1
}

# Map to GF180 cells using ABC
# -D sets target delay in picoseconds (10000ps = 10ns = 100MHz clock)

puts "  Target clock period: 10ns (100 MHz)"

# ==============================================================================
# 2.1 INITIAL MAPPING (BEFORE TIMING OPTIMIZATION)
# ==============================================================================

puts "  Running initial technology mapping..."

# First pass: Map flip-flops explicitly to GF180 cells
puts "  Step 1: Mapping sequential elements (flip-flops)..."
dfflibmap -liberty $liberty_file

# Second pass: Map combinational logic to GF180 cells
puts "  Step 2: Mapping combinational logic..."
abc -liberty $liberty_file -D $-clock_period

# Show initial statistics
puts "\n  Initial PDK-mapped statistics:"
stat

# ==============================================================================
# 2.2 TIMING-AWARE OPTIMIZATION (NEW)
# ==============================================================================

if {$timing_optimization} {
    puts "\n=== Phase 2.2: Timing-Aware Optimization ==="
    puts "  Applying timing optimization passes..."

    # Balance delays for better timing
    puts "  Step 1: Balancing delays..."
    balance

    # Optimize for timing
    puts "  Step 2: Timing optimization..."
    opt_time

    # Show statistics after timing optimization
    puts "\n  Statistics after timing optimization:"
    stat
}

# ==============================================================================
# 3. STATISTICS AND VALIDATION
# ==============================================================================

puts "\n=== Phase 3: Statistics After PDK Mapping ==="
stat

puts "\n=== Phase 4: Design Check ==="
check

# ==============================================================================
# 4. AREA OPTIMIZATION (NEW)
# ==============================================================================

if {$area_optimization} {
    puts "\n=== Phase 4.1: Area Optimization ==="
    puts "  Applying area optimization passes..."

    # Optimize for area
    puts "  Step 1: Area optimization..."
    opt_area

    # Show statistics after area optimization
    puts "\n  Statistics after area optimization:"
    stat
}

# ==============================================================================
# 5. WRITE GF180-MAPPED NETLIST
# ==============================================================================

puts "\n=== Phase 5: Writing GF180-Mapped Netlist ==="

# Write Verilog netlist with GF180 cells
write_verilog -noattr ../build/output/core_top_gf180.v
puts "  Written: ../build/output/core_top_gf180.v"

# ==============================================================================
# 6. TIMING REPORT (NEW)
# ==============================================================================

puts "\n=== Phase 6: Generating Timing Report ==="

# Generate timing report
tee -a ../build/reports/timing_report.txt "GF180 PDK Timing Report"
tee -a ../build/reports/timing_report.txt "========================================"
tee -a ../build/reports/timing_report.txt ""
tee -a ../build/reports/timing_report.txt "Target Clock Period: ${-clock_period}ps (${expr {$-clock_period / 1000}}ns)"
tee -a ../build/reports/timing_report.txt "Target Frequency: ${expr {10000000000.0 / $-clock_period}} MHz"
tee -a ../build/reports/timing_report.txt ""
tee -a ../build/reports/timing_report.txt "Optimization Settings:"
tee -a ../build/reports/timing_report.txt "  - Timing optimization: $timing_optimization"
tee -a ../build/reports/timing_report.txt "  - Area optimization: $area_optimization"
tee -a ../build/reports/timing_report.txt ""
tee -a ../build/reports/timing_report.txt "Liberty File: $liberty_file"
tee -a ../build/reports/timing_report.txt "Corner: $corner_name"
tee -a ../build/reports/timing_report.txt ""
tee -a ../build/reports/timing_report.txt "Next Steps:"
tee -a ../build/reports/timing_report.txt "  1. Run static timing analysis with OpenSTA"
tee -a ../build/reports/timing_report.txt "  2. Check for setup/hold violations"
tee -a ../build/reports/timing_report.txt "  3. Proceed to place & route with OpenROAD"
tee -a ../build/reports/timing_report.txt ""

# ==============================================================================
# 7. SUMMARY
# ==============================================================================

puts "\n================================================================================"
puts "GF180 PDK MAPPING COMPLETE"
puts "================================================================================"
puts "\nOutput Netlist: ../build/output/core_top_gf180.v"
puts "\nReports:"
puts "  - Timing report: ../build/reports/timing_report.txt"
puts "\nNext Steps:"
puts "  1. Review cell types used:"
puts "     grep 'gf180mcu_fd_sc_mcu9t5v0__' core_top_gf180.v | sed 's/(.*//g' | sort -u"
puts "  2. Run timing analysis with OpenSTA"
puts "  3. Proceed to place & route with OpenROAD"
puts "\n================================================================================"
