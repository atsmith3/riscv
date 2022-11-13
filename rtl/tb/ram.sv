/*
 * Parameterized Single Port Memory with Customizable Response Delay
 *
 * 2022-11-12
 */

`timescale 1ns/1ns

module memory_model #(
  parameter DATA_WIDTH=8,
  parameter ADDR_WIDTH=32,
  parameter DELAY=0,
  parameter MEM_INIT_FILE="/home/andrew/proj/riscv/rtl/tb/test_roms/test.mem"
) 
( input clk,
  input read,
  input write,
  input logic [DATA_WIDTH-1:0] data_in,
  output logic [DATA_WIDTH-1:0] data_out,
  input logic [ADDR_WIDTH-1:0] addr,
  output logic resp);

  reg [DATA_WIDTH-1:0] mem [2**ADDR_WIDTH];

  initial begin
    $readmemh(MEM_INIT_FILE,mem);
  end

  always_ff @ ( posedge clk ) begin
    if (write) begin
      mem[addr] <= data_in;
    end
  end

  assign data_out = read ? mem[addr] : 'b0;
  assign resp = 1'b1;

endmodule

`ifdef TESTBENCH
module tb ();
  localparam DATA_WIDTH=8;
  localparam ADDR_WIDTH=4;

  reg clk;
  reg read;
  reg write;
  reg resp;
  reg [DATA_WIDTH-1:0] data_in;
  reg [DATA_WIDTH-1:0] data_out;
  reg [ADDR_WIDTH-1:0] addr;

  initial begin
    $dumpfile("test.vcd");
    $dumpvars(0,tb);
  end

  memory_model #(.ADDR_WIDTH(ADDR_WIDTH)) u_single_port_ram (
    .clk(clk),
    .read(read),
    .write(write),
    .resp(resp),
    .data_in(data_in),
    .data_out(data_out),
    .addr(addr));

  always #10 clk = ~clk;

  initial begin
    clk <= 0;
    read <= 0;
    write <= 0;
    data_in <= 0;
    addr <= 0;
    
    for (integer i = 0; i < 2**ADDR_WIDTH; i= i+1) begin
      repeat (1) @(posedge clk) addr <= i; read <= 1; write <= 0;
    end
    
    #100 $finish;
  end
endmodule
`endf
