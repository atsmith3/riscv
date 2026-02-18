# Create the ILA core
create_debug_core u_ila_0 ila

# Configure the probe ports
set_property C_DATA_DEPTH 1024 [get_debug_cores u_ila_0]
set_property C_TRIGIN_EN false [get_debug_cores u_ila_0]

# Connect to your design signals
set data [get_nets [list rst_btn_sync1]]
set_property port_width [llength $data] [get_debug_ports u_ila_0/probe0]
connect_debug_port u_ila_0/probe0 $data


set data [get_nets [list mem_resp]]
create_debug_port u_ila_0 probe1
set_property port_width [llength $data] [get_debug_ports u_ila_0/probe1]
connect_debug_port u_ila_0/probe1 $data

set data [get_nets [list mem_read]]
create_debug_port u_ila_0 probe2
set_property port_width [llength $data] [get_debug_ports u_ila_0/probe2]
connect_debug_port u_ila_0/probe2 $data

set data [get_nets [list mem_write]]
create_debug_port u_ila_0 probe3
set_property port_width [llength $data] [get_debug_ports u_ila_0/probe3]
connect_debug_port u_ila_0/probe3 $data

#set_property mark_debug true 
#set_property mark_debug true 
#set_property mark_debug true 

set data [get_nets [list {mem_rdata[2]} {mem_rdata[0]} {mem_rdata[22]} {mem_rdata[24]} {mem_rdata[25]} {mem_rdata[23]} {mem_rdata[18]} {mem_rdata[20]} {mem_rdata[21]} {mem_rdata[19]} {mem_rdata[14]} {mem_rdata[16]} {mem_rdata[17]} {mem_rdata[15]} {mem_rdata[1]} {mem_rdata[3]} {mem_rdata[4]} {mem_rdata[5]} {mem_rdata[6]} {mem_rdata[7]} {mem_rdata[8]} {mem_rdata[9]} {mem_rdata[10]} {mem_rdata[12]} {mem_rdata[30]} {mem_rdata[31]} {mem_rdata[26]} {mem_rdata[28]} {mem_rdata[29]} {mem_rdata[27]} {mem_rdata[13]} {mem_rdata[11]}]]
create_debug_port u_ila_0 probe4
set_property port_width [llength $data] [get_debug_ports u_ila_0/probe4]
connect_debug_port u_ila_0/probe4 $data

set data [get_nets [list {mem_addr[11]} {mem_addr[5]} {mem_addr[2]} {mem_addr[3]} {mem_addr[4]} {mem_addr[6]} {mem_addr[7]} {mem_addr[8]} {mem_addr[9]} {mem_addr[15]} {mem_addr[16]} {mem_addr[13]} {mem_addr[14]} {mem_addr[19]} {mem_addr[20]} {mem_addr[17]} {mem_addr[18]} {mem_addr[23]} {mem_addr[24]} {mem_addr[21]} {mem_addr[22]} {mem_addr[27]} {mem_addr[28]} {mem_addr[25]} {mem_addr[26]} {mem_addr[31]} {mem_addr[29]} {mem_addr[30]} {mem_addr[10]} {mem_addr[12]}]]
create_debug_port u_ila_0 probe5
set_property port_width [llength $data] [get_debug_ports u_ila_0/probe5]
connect_debug_port u_ila_0/probe5 $data

set data [get_nets [list {u_core_top/u_pc/out[7]} {u_core_top/u_pc/out[3]} {u_core_top/u_pc/out[0]} {u_core_top/u_pc/out[1]} {u_core_top/u_pc/out[2]} {u_core_top/u_pc/out[4]} {u_core_top/u_pc/out[5]} {u_core_top/u_pc/out[6]} {u_core_top/u_pc/out[8]} {u_core_top/u_pc/out[9]} {u_core_top/u_pc/out[10]} {u_core_top/u_pc/out[11]} {u_core_top/u_pc/out[12]} {u_core_top/u_pc/out[13]} {u_core_top/u_pc/out[14]} {u_core_top/u_pc/out[15]} {u_core_top/u_pc/out[16]} {u_core_top/u_pc/out[17]} {u_core_top/u_pc/out[18]} {u_core_top/u_pc/out[19]} {u_core_top/u_pc/out[20]} {u_core_top/u_pc/out[21]} {u_core_top/u_pc/out[22]} {u_core_top/u_pc/out[23]} {u_core_top/u_pc/out[24]} {u_core_top/u_pc/out[25]} {u_core_top/u_pc/out[26]} {u_core_top/u_pc/out[27]} {u_core_top/u_pc/out[28]} {u_core_top/u_pc/out[29]} {u_core_top/u_pc/out[30]} {u_core_top/u_pc/out[31]}]]
create_debug_port u_ila_0 probe6
set_property port_width [llength $data] [get_debug_ports u_ila_0/probe6]
connect_debug_port u_ila_0/probe6 $data

# Connect the clock
connect_debug_port u_ila_0/clk [get_nets {clk}]
implement_debug_core
write_debug_probes -force debug_probes.ltx
