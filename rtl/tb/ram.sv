/*
 * Ideal Single Port Memory Model for Testing
 */

`timescale 1ns/1ns

// TODO: Add Delay Parameter & Mem Init FIle Parameter
module memory_model #(
  parameter DATA_WIDTH=8,
  parameter ADDR_WIDTH=32
) 
( input clk,
  input logic [DATA_WIDTH-1:0] data_in,
  output logic [DATA_WIDTH-1:0] data_out,
  input logic [ADDR_WIDTH-1:0] addr,
  input logic we, 
  input logic cs,
  output logic vld);

  reg [DATA_WIDTH-1:0] output_buf;
  reg [DATA_WIDTH-1:0] mem [2**ADDR_WIDTH];

  initial begin
    output_buf <= 0;
    $readmemh("test_roms/test.mem",mem,0,7);
  end

  always_ff @ ( posedge clk ) begin
    if (cs) begin
      if (we) begin
        mem[addr] <= data_in;
      end
    end
  end

  assign data_out = cs & !we ? mem[addr] : 'b0;
  assign vld = 1'b1;

endmodule

`ifdef TESTBENCH
module tb ();
  localparam DATA_WIDTH=8;
  localparam ADDR_WIDTH=4;

  reg clk;
  reg cs;
  reg we;
  reg [DATA_WIDTH-1:0] data_in;
  reg [DATA_WIDTH-1:0] data_out;
  reg [ADDR_WIDTH-1:0] addr;

  initial begin
    $dumpfile("test.vcd");
    $dumpvars(0,tb);
  end

  memory_model #(.ADDR_WIDTH(ADDR_WIDTH)) u_single_port_ram (
    .clk(clk),
    .cs(cs),
    .we(we),
    .data_in(data_in),
    .data_out(data_out),
    .addr(addr));

  always #10 clk = ~clk;

  initial begin
    clk <= 0;
    cs <= 0;
    we <= 0;
    data_in <= 0;
    addr <= 0;
    
    //for (integer i = 0; i < 2**ADDR_WIDTH; i= i+1) begin
    //  repeat (1) @(posedge clk) addr <= i; we <= 1; cs <=1; data_in <= $random;
    //end
    
    for (integer i = 0; i < 2**ADDR_WIDTH; i= i+1) begin
      repeat (1) @(posedge clk) addr <= i; we <= 0; cs <= 1;
    end
    
    #100 $finish;
  end
endmodule
`endif
