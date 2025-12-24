# ==============================================================================
# GF180 PDK Technology Mapping Script
# Maps Yosys gate primitives to GF180 standard cells
# ==============================================================================
# Usage: yosys -c pdk_map.tcl
# ==============================================================================

yosys -import

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
}
puts "  Using Liberty file: $liberty_file"

# Map to GF180 cells using ABC
# -D sets target delay in picoseconds (10000ps = 10ns = 100MHz clock)
# Adjust -D value based on your target frequency:
#   - 100 MHz = -D 10000 (10ns period)
#   -  50 MHz = -D 20000 (20ns period)
#   - 200 MHz = -D 5000  (5ns period)

puts "  Target clock period: 10ns (100 MHz)"
puts "  Running two-pass technology mapping..."

# First pass: Map flip-flops explicitly to GF180 cells
puts "  Step 1: Mapping sequential elements (flip-flops)..."
dfflibmap -liberty $liberty_file

# Second pass: Map combinational logic to GF180 cells
puts "  Step 2: Mapping combinational logic..."
abc -liberty $liberty_file -D 10000

# ==============================================================================
# 3. STATISTICS AND VALIDATION
# ==============================================================================

puts "\n=== Phase 3: Statistics After PDK Mapping ==="
stat

puts "\n=== Phase 4: Design Check ==="
check

# ==============================================================================
# 4. WRITE GF180-MAPPED NETLIST
# ==============================================================================

puts "\n=== Phase 5: Writing GF180-Mapped Netlist ==="

# Write Verilog netlist with GF180 cells
write_verilog -noattr ../build/output/core_top_gf180.v
puts "  Written: ../build/output/core_top_gf180.v"

# Also write SDF for timing simulation (if you need it later)
# write_sdf ../build/output/core_top_gf180.sdf

puts "\n================================================================================"
puts "GF180 PDK MAPPING COMPLETE"
puts "================================================================================"
puts "\nOutput Netlist: ../build/output/core_top_gf180.v"
puts "\nNext Steps:"
puts "  1. Review cell types used: grep 'gf180mcu_fd_sc_mcu9t5v0__' core_top_gf180.v | sed 's/(.*//g' | sort -u"
puts "  2. Run timing analysis with OpenSTA"
puts "  3. Proceed to place & route with OpenROAD"
puts "\n================================================================================"
