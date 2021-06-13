/*
 * Testbench for Register
 *
 * 20210612
 */

module tb;

  reg clk;
  reg rstn;
  reg wr;
  reg [31:0] in_data;
  reg [31:0] out_data;


  initial begin
    rstn <= 1;
    clk <= 1;
    in_data <= 0;
    forever begin
      #1;
      clk <= ~clk;
      $display("[%d] %x,%x,%x,%x,%x",$time,clk,rstn,wr,in_data,out_data);
    end
  end

  initial begin
    #0;
    rstn <= 0;
    #2;
    rstn <= 1;
    #2;
    in_data <= 32'ha5a5a5a5;
    wr <= 1;
    #2;
    in_data <= 0;
    wr <= 0;
    #32;
    rstn <= 0;
    #2;
    rstn <= 0;
    #1;
    rstn <= 1;
    #1;
    in_data <= 32'hdeadbeef;
    wr <= 1;
    #2;
    in_data <= 0;
    wr <= 0;
    #32;
    $finish;
  end

  register u_register (
    .clk(clk),
    .rstn(rstn),
    .in(in_data),
    .out(out_data),
    .wr(wr)
  );

endmodule
