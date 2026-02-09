# place.tcl — Placement
#
# Usage: vivado -mode batch -source scripts/place.tcl \
#          -tclargs <output_dir> <input_dcp>

set output_dir [lindex $argv 0]
set input_dcp  [lindex $argv 1]

# Open post-optimization checkpoint
open_checkpoint $input_dcp

# Place
place_design

# Reports
report_utilization      -file $output_dir/utilization.rpt
report_timing_summary   -file $output_dir/timing_summary.rpt
report_clock_utilization -file $output_dir/clock_utilization.rpt

# Save checkpoint
write_checkpoint -force $output_dir/post_place.dcp

puts "=== Placement complete. Checkpoint: $output_dir/post_place.dcp ==="
