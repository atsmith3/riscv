# opt.tcl — Logic optimization (post-synthesis)
#
# Usage: vivado -mode batch -source scripts/opt.tcl \
#          -tclargs <output_dir> <input_dcp>

set output_dir [lindex $argv 0]
set input_dcp  [lindex $argv 1]

# Open post-synthesis checkpoint
open_checkpoint $input_dcp

# Optimize
opt_design

# Reports
report_utilization    -file $output_dir/utilization.rpt
report_timing_summary -file $output_dir/timing_summary.rpt

# Save checkpoint
write_checkpoint -force $output_dir/post_opt.dcp

puts "=== Optimization complete. Checkpoint: $output_dir/post_opt.dcp ==="
