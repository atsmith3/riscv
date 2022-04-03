/* core_top.sv
 * 
 * Contains the datapath and all the top level modules that make up the core.
 */

module core_top (
  input wire clk,
  input wire rst_n,
  input [31:0] mem_rdata,
  output [31:0] mem_wdata,
  output [31:0] mem_addr,
  input rvalid,
  output wvalid
);



wire [31:0] databus;
wire [31:0] ir_out;
wire [31:0] pc_out;
wire [31:0] pc_in;
wire [31:0] pc_incr;
wire load_ir;
wire load_pc;
wire pc_mux_sel;
wire mdr_mux_sel;
wire [1:0] databus_mux_sel;

register #(.WIDTH(32), .INIT(0)) u_ir (.clk(clk), .rstn(rst_n), .in(databus), .out(ir_out), .load(load_ir));
register #(.WIDTH(32), .INIT('h3000)) u_pc (.clk(clk), .rstn(rst_n), .in(pc_in), .out(pc_out), .load(load_pc));

control u_control (
  .clk(clk),
  .rst_n(rst_n), 
  .load_mar(),
  .load_pc(load_pc),
  .load_ir(load_ir),
  .load_mdr(),
  .pc_mux_sel(pc_mux_sel),
  .databus_mux_sel(databus_mux_sel),
  .mdr_mux_sel(mdr_mux_sel),
  .mdr_valid(1'b1));

mux4 #(.WIDTH(32)) u_databus_mux (
  .sel(databus_mux_sel),
  .a(pc_out),
  .b(),
  .c(),
  .d(),
  .y(databus));

mux2 #(.WIDTH(32)) u_pc_mux (
  .sel(pc_mux_sel),
  .a(),
  .b(),
  .y(pc_in));

assign pc_incr = pc_out + 1;
assign pc_in = (pc_mux_sel ? pc_incr : databus);

endmodule : core_top
