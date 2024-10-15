/*
 * Testbench for POTATO RISC-V CORE
 */

`timescale 1ns/1ns

module tb ();
  localparam WIDTH=32;
  localparam ADDR_WIDTH=16;

  reg clk;
  reg rst_n;
  reg write;
  reg read;
  reg resp;
  reg [WIDTH-1:0] rdata;
  reg [WIDTH-1:0] wdata;
  reg [WIDTH-1:0] addr;

  core_top u_POTATO (
    .clk(clk),
    .rst_n(rst_n),
    .mem_rdata(rdata),
    .mem_resp(resp),
    .mem_wdata(wdata),
    .mem_addr(addr),
    .mem_read(read),
    .mem_write(write));

  memory_model #(
    .ADDR_WIDTH(ADDR_WIDTH),
    .DATA_WIDTH(WIDTH),
    .DELAY(4),
    //.MEM_INIT_FILE("../../test/subtract/subtract.ini")) mem (
    .MEM_INIT_FILE("../../test/gcd/gcd.ini")) mem (
    //.MEM_INIT_FILE("../../test/add/add.ini")) mem (
    .clk(clk),
    .rst_n(rst_n),
    .read(read),
    .write(write),
    .resp(resp),
    .addr(addr[ADDR_WIDTH-1:0]),
    .data_in(wdata),
    .data_out(rdata));

  always #1 clk = ~clk;

  initial begin
    $dumpfile("core.vcd");
    $dumpvars(0,tb);

    clk <= 0;
    rst_n <= 0;

    #10 rst_n <= 1;
    #100000 $finish;
  end
endmodule
