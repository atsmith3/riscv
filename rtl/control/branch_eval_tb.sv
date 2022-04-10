/*
 * Testbench for branch_eval
 */

`define WIDTH 32

`include "datatypes.sv"

module tb;
  
  reg [`WIDTH-1:0] rs1, rs2;
  reg [2:0] op;
  reg exception;
  reg branch;

  initial begin
    rs1 = 0;
    rs2 = 0;
    op = 0;
    forever begin
      #1;
      $display("[%d] %x,%x,%x,%x,%x",$time,op,rs1,rs2,branch,exception);
    end
  end

  initial begin
    #0;
    op = BEQ;
    $display("------------ BEQ -----------");
    rs1 = 0;
    rs2 = 0;
    #1;
    rs1 = 10;
    rs2 = 10;
    #1;
    rs1 = 10;
    rs2 = -5;
    #1;
    rs1 = 32'hFFFFFFFF;
    rs2 = 1;
    #1;
    rs1 = 32'hFFFFFFFF;
    rs2 = 32'hFFFFFFFF;
    #1;
    rs1 = -5;
    rs2 = -10; 
    #1;
    op = BNE;
    $display("------------ BNE -----------");
    rs1 = 0;
    rs2 = 0;
    #1;
    rs1 = 10;
    rs2 = 10;
    #1;
    rs1 = 10;
    rs2 = -5;
    #1;
    rs1 = 32'hFFFFFFFF;
    rs2 = 1;
    #1;
    rs1 = 32'hFFFFFFFF;
    rs2 = 32'hFFFFFFFF;
    #1;
    rs1 = -5;
    rs2 = -10; 
    #1;
    op = BRANCH_RESERVED_1;
    $display("------------ BRANCH_RESERVED_1 -----------");
    rs1 = 0;
    rs2 = 0;
    #1;
    rs1 = 10;
    rs2 = 10;
    #1;
    rs1 = 10;
    rs2 = -5;
    #1;
    rs1 = 32'hFFFFFFFF;
    rs2 = 1;
    #1;
    rs1 = 32'hFFFFFFFF;
    rs2 = 32'hFFFFFFFF;
    #1;
    rs1 = -5;
    rs2 = -10; 
    #1;
    op = BRANCH_RESERVED_2;
    $display("------------ BRANCH_RESERVED_2 -----------");
    rs1 = 0;
    rs2 = 0;
    #1;
    rs1 = 10;
    rs2 = 10;
    #1;
    rs1 = 10;
    rs2 = -5;
    #1;
    rs1 = 32'hFFFFFFFF;
    rs2 = 1;
    #1;
    rs1 = 32'hFFFFFFFF;
    rs2 = 32'hFFFFFFFF;
    #1;
    rs1 = -5;
    rs2 = -10; 
    #1;
    op = BLT;
    $display("------------ BLT -----------");
    rs1 = 0;
    rs2 = 0;
    #1;
    rs1 = 10;
    rs2 = 10;
    #1;
    rs1 = 10;
    rs2 = -5;
    #1;
    rs1 = 32'hFFFFFFFF;
    rs2 = 1;
    #1;
    rs1 = 32'hFFFFFFFF;
    rs2 = 32'hFFFFFFFF;
    #1;
    rs1 = -5;
    rs2 = -10; 
    #1;
    op = BGE;
    $display("------------ BGE -----------");
    rs1 = 0;
    rs2 = 0;
    #1;
    rs1 = 10;
    rs2 = 10;
    #1;
    rs1 = 10;
    rs2 = -5;
    #1;
    rs1 = 32'hFFFFFFFF;
    rs2 = 1;
    #1;
    rs1 = 32'hFFFFFFFF;
    rs2 = 32'hFFFFFFFF;
    #1;
    rs1 = -5;
    rs2 = -10; 
    #1;
    op = BLTU;
    $display("------------ BLTU -----------");
    rs1 = 0;
    rs2 = 0;
    #1;
    rs1 = 10;
    rs2 = 10;
    #1;
    rs1 = 10;
    rs2 = -5;
    #1;
    rs1 = 32'hFFFFFFFF;
    rs2 = 1;
    #1;
    rs1 = 32'hFFFFFFFF;
    rs2 = 32'hFFFFFFFF;
    #1;
    rs1 = -5;
    rs2 = -10; 
    #1;
    op = BGEU;
    $display("------------ BGEU -----------");
    rs1 = 0;
    rs2 = 0;
    #1;
    rs1 = 10;
    rs2 = 10;
    #1;
    rs1 = 10;
    rs2 = -5;
    #1;
    rs1 = 32'hFFFFFFFF;
    rs2 = 1;
    #1;
    rs1 = 32'hFFFFFFFF;
    rs2 = 32'hFFFFFFFF;
    #1;
    rs1 = -5;
    rs2 = -10; 
    #1;
    $finish;
  end

  branch_eval #(.WIDTH(`WIDTH)) u_dut (
    .rs1(rs1),
    .rs2(rs2),
    .func(op),
    .branch(branch),
    .exception(exception)
  );
endmodule

