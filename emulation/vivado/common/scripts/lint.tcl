# lint.tcl — RTL elaboration (syntax, hierarchy, connectivity check)
#
# Usage: vivado -mode batch -source scripts/lint.tcl \
#          -tclargs <output_dir> <rtl_dir> <part> <xdc_dir> <common_rtl_dir>

set output_dir     [lindex $argv 0]
set rtl_dir        [lindex $argv 1]
set part           [lindex $argv 2]
set xdc_dir        [lindex $argv 3]
set common_rtl_dir [lindex $argv 4]

# Read RTL sources in dependency order (datatypes.sv pulled in via `include)
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
read_verilog -sv $common_rtl_dir/bram_memory.sv
read_verilog -sv emu_top.sv

# Read constraints
read_xdc $xdc_dir/Arty-S7-50-Master.xdc

# RTL-only elaboration — validates syntax, hierarchy, and connectivity
synth_design -rtl -top emu_top -part $part -include_dirs $rtl_dir

# Lint diagnostics
report_compile_order -file $output_dir/compile_order.rpt

puts "=== Lint complete ==="
