# synth.tcl — Out-of-context synthesis
#
# Usage: vivado -mode batch -source scripts/synth.tcl \
#          -tclargs <output_dir> <rtl_dir> <part> <xdc_dir>

set output_dir [lindex $argv 0]
set rtl_dir    [lindex $argv 1]
set part       [lindex $argv 2]
set xdc_dir    [lindex $argv 3]

# Re-read all sources (cannot resume from RTL-only checkpoint for full synthesis)
read_verilog -sv $rtl_dir/program_register.sv
read_verilog -sv $rtl_dir/dff_init.sv
read_verilog -sv $rtl_dir/regfile.sv
read_verilog -sv $rtl_dir/mux4.sv
read_verilog -sv $rtl_dir/alu/alu.sv
read_verilog -sv $rtl_dir/byte_lane.sv
read_verilog -sv $rtl_dir/csr_alu.sv
read_verilog -sv $rtl_dir/csr_file.sv
read_verilog -sv $rtl_dir/control/imm_gen.sv
read_verilog -sv $rtl_dir/control/decoder.sv
read_verilog -sv $rtl_dir/control.sv
read_verilog -sv $rtl_dir/core_top.sv
read_verilog -sv bram_memory.sv
read_verilog -sv emu_top.sv

# Read constraints
read_xdc $xdc_dir/Arty-S7-50-Master.xdc

# Full synthesis with pin constraints
synth_design -top emu_top -part $part -include_dirs $rtl_dir

# Reports
report_utilization    -file $output_dir/utilization.rpt
report_timing_summary -file $output_dir/timing_summary.rpt
report_methodology    -file $output_dir/methodology.rpt

# Save checkpoint
write_checkpoint -force $output_dir/post_synth.dcp

puts "=== Synthesis complete. Checkpoint: $output_dir/post_synth.dcp ==="
