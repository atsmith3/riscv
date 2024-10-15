/*
 * Testbench for core_top
 */

module tb;
  reg clk;
  reg rst_n;
  reg mem_resp;
  reg [31:0] mem_rdata;
  reg [31:0] mem_wdata;
  reg [31:0] mem_addr;

  initial begin
    rst_n <= 1;
    clk <= 1;
    mem_resp <= 1;
    mem_rdata <= 1000;
    forever begin
      #1;
      clk <= ~clk;
      $display("[%d] %x,%x,%x,%x",$time,clk,rst_n,mem_addr,mem_rdata,mem_wdata,mem_resp);
    end
  end

  initial begin
    #0;
    rst_n <= 0;
    #2;
    rst_n <= 1;
    #100;
    $finish;
  end

  core_top u_core_top (
    .clk(clk),
    .rst_n(rst_n),
    .mem_rdata(mem_rdata),
    .mem_wdata(mem_wdata),
    .mem_addr(mem_addr),
    .mem_resp(mem_rvalid)
  );
endmodule
