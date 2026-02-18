# route.tcl — Routing
#
# Usage: vivado -mode batch -source scripts/route.tcl \
#          -tclargs <output_dir> <input_dcp>

set output_dir [lindex $argv 0]
set input_dcp  [lindex $argv 1]

# Open post-placement checkpoint
open_checkpoint $input_dcp

# Route
route_design

# Reports
report_utilization    -file $output_dir/utilization.rpt
report_timing_summary -file $output_dir/timing_summary.rpt
report_route_status   -file $output_dir/route_status.rpt
report_power          -file $output_dir/power.rpt

# Save checkpoint
write_checkpoint -force $output_dir/post_route.dcp

puts "=== Routing complete. Checkpoint: $output_dir/post_route.dcp ==="
