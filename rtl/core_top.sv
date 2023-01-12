/* core_top.sv
 * 
 * Contains the datapath and all the top level modules that make up the core.
 */

module core_top (
  input logic clk,
  input logic rst_n,
  input logic [31:0] mem_rdata,
  input logic mem_resp,
  output logic [31:0] mem_wdata,
  output logic [31:0] mem_addr,
  output logic mem_read,
  output logic mem_write
);

databus_mux_sel_t databus_mux_sel;
rs2_mux_sel_t rs2_mux_sel;
wire [31:0] alu_out;
wire [31:0] databus;
wire [31:0] ir_out;
wire [31:0] mar_out;
wire [31:0] mdr_out;
wire [31:0] mdr_in;
wire [31:0] pc_in;
wire [31:0] pc_incr;
wire [31:0] pc_out;
wire [31:0] rd_in;
wire [31:0] rs1_out;
wire [31:0] rs2_mux_out;
wire [31:0] rs2_out;
wire [4:0] rd;
wire [4:0] rs1;
wire [4:0] rs2;
wire [3:0] op;
wire beq, blt, bltu;
wire beq_in, blt_in, bltu_in;
wire load_bsr;
wire load_ir;
wire load_pc;
wire mdr_mux_sel;
wire pc_mux_sel;
wire [31:0] imm;
wire [31:0] rs2_sel;


register #(.WIDTH(32), .INIT(0)) u_ir (.clk(clk), .rstn(rst_n), .in(databus), .out(ir_out), .load(load_ir));
register #(.WIDTH(32), .INIT('h0)) u_pc (.clk(clk), .rstn(rst_n), .in(pc_in), .out(pc_out), .load(load_pc));
register #(.WIDTH(3), .INIT('h0)) u_bsr (.clk(clk), .rstn(rst_n), .in({beq_in, blt_in, bltu_in}), .out({beq, blt, bltu}), .load(load_bsr));
register #(.WIDTH(32), .INIT(0)) u_mar (.clk(clk), .rstn(rst_n), .in(databus), .out(mar_out), .load(load_mar));
register #(.WIDTH(32), .INIT(0)) u_mdr (.clk(clk), .rstn(rst_n), .in(mdr_in), .out(mdr_out), .load(load_mdr));

assign mem_addr = mar_out;
assign mem_wdata = mdr_out;

control u_control (
  .clk(clk),
  .rst_n(rst_n), 
  .load_mar(load_mar),
  .load_pc(load_pc),
  .load_ir(load_ir),
  .load_mdr(load_mdr),
  .load_bsr(load_bsr),
  .mem_write(mem_write),
  .mem_read(mem_read),
  .mem_resp(mem_resp),
  .pc_mux_sel(pc_mux_sel),
  .databus_mux_sel(databus_mux_sel),
  .mdr_mux_sel(mdr_mux_sel),
  .alu_op(),
  .ir(ir_out),
  .rs1_val(rs1_out),
  .rs2_val(rs1_out),
  .rs1(rs1),
  .rs2(rs2),
  .rd(rd));

alu #(.WIDTH(32)) u_alu (
  .rs1(rs1_out),
  .rs2(rs2_mux_out),
  .op(op),
  .bsr({beq_in, blt_in, bltu_in}),
  .rd(alu_out));

mux4 #(.WIDTH(32)) u_databus_mux (
  .sel(databus_mux_sel),
  .a(pc_out),
  .b(alu_out),
  .c(mdr_out),
  .d(mar_out),
  .y(databus));

mux2 #(.WIDTH(32)) u_pc_mux (
  .sel(pc_mux_sel),
  .a(pc_incr),
  .b(databus),
  .y(pc_in));

mux2 #(.WIDTH(32)) u_mdr_mux (
  .sel(mdr_mux_sel),
  .a(mem_rdata),
  .b(databus),
  .y(mdr_in));

mux4 #(.WIDTH(32)) u_rs2_mux (
  .sel(rs2_mux_sel),
  .a(rs2_out),
  .b(rs2_sel),
  .c(imm),
  .d(pc_out),
  .y(rs2_mux_out));

assign pc_incr = pc_out + 4;

endmodule : core_top
