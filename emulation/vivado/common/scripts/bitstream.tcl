# bitstream.tcl — Bitstream generation
#
# Usage: vivado -mode batch -source scripts/bitstream.tcl \
#          -tclargs <output_dir> <input_dcp> <top>

set output_dir [lindex $argv 0]
set input_dcp  [lindex $argv 1]
set top        [lindex $argv 2]

# Open post-route checkpoint
open_checkpoint $input_dcp

# Generate bitstream
write_bitstream -force $output_dir/${top}.bit

puts "=== Bitstream complete. Output: $output_dir/${top}.bit ==="
