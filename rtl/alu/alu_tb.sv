/*
 * Testbench for alu
 */

`define WIDTH 32

`include "datatypes.sv"

module tb;
  
  reg [`WIDTH-1:0] rs1, rs2, rd;
  reg [3:0] op;

  initial begin
    rs1 = 0;
    rs2 = 0;
    op = 0;
    forever begin
      #2;
      $display("[%d] %x,%x,%x,%x",$time,op,rs1,rs2,rd);
    end
  end

  initial begin
    #0;
    op = ALU_ADD;
    $display("ALU_ADD");
    rs1 = 0;
    rs2 = 0;
    #2;
    rs1 = 10;
    rs2 = 10;
    #2;
    rs1 = 10;
    rs2 = -5;
    #2;
    rs1 = 32'hFFFFFFFF;
    rs2 = 1;
    #2;
    rs1 = 32'hFFFFFFFF;
    rs2 = 32'hFFFFFFFF;
    #2;
    rs1 = -5;
    rs2 = -10; 
    #2;
    op = ALU_SLL;
    $display("ALU_SLL");
    rs1 = 32'hbadcaffe;
    rs2 = 4;
    #2;
    rs1 = 32'ha5a5a5a5;
    rs2 = 1;
    #2;
    rs1 = 32'ha5a5a5a5;
    rs2 = -1;
    #2;
    op = ALU_SLT;
    $display("ALU_SLT");
    rs1 = 10;
    rs2 = 4;
    #2;
    rs1 = 4;
    rs2 = 10;
    #2;
    rs1 = -5;
    rs2 = -3;
    #2;
    rs1 = -3;
    rs2 = -5;
    #2;
    rs1 = -10;
    rs2 = 10;
    #2;
    rs1 = 0;
    rs2 = 0;
    #2;
    rs1 = 0;
    rs2 = 3;
    #2;
    op = ALU_SLTU;
    $display("ALU_SLTU");
    rs1 = 10;
    rs2 = 4;
    #2;
    rs1 = 4;
    rs2 = 10;
    #2;
    rs1 = -5;
    rs2 = -3;
    #2;
    rs1 = -3;
    rs2 = -5;
    #2;
    rs1 = -10;
    rs2 = 10;
    #2;
    rs1 = 0;
    rs2 = 0;
    #2;
    rs1 = 0;
    rs2 = 3;
    #2;
    op = ALU_XOR;
    $display("ALU_XOR");
    rs1 = 0;
    rs2 = 0;
    #2;
    rs1 = 32'h5a5a5a5a;
    rs2 = -1;
    #2;
    rs1 = 32'ha5a5a5a5;
    rs2 = 32'h5a5a5a5a;
    #2;
    op = ALU_SRL;
    $display("ALU_SRL");
    rs1 = 32'hbadcaffe;
    rs2 = 4;
    #2;
    rs1 = 32'ha5a5a5a5;
    rs2 = 1;
    #2;
    rs1 = 32'ha5a5a5a5;
    rs2 = -1;
    #2;
    op = ALU_OR;
    $display("ALU_OR");
    rs1 = 0;
    rs2 = 0;
    #2;
    rs1 = 32'h5a5a5a5a;
    rs2 = -1;
    #2;
    rs1 = 32'ha5a5a5a5;
    rs2 = 32'h5a5a5a5a;
    #2;
    op = ALU_AND;
    $display("ALU_AND");
    rs1 = 0;
    rs2 = 0;
    #2;
    rs1 = 32'h5a5a5a5a;
    rs2 = -1;
    #2;
    rs1 = 32'ha5a5a5a5;
    rs2 = 32'h5a5a5a5a;
    #2;
    op = ALU_SUB;
    $display("ALU_SUB");
    rs1 = 0;
    rs2 = 0;
    #2;
    rs1 = 10;
    rs2 = 10;
    #2;
    rs1 = 10;
    rs2 = -5;
    #2;
    rs1 = 32'hFFFFFFFF;
    rs2 = 1;
    #2;
    rs1 = 32'hFFFFFFFF;
    rs2 = 32'hFFFFFFFF;
    #2;
    rs1 = -5;
    rs2 = -10; 
    #2;
    op = ALU_SRA;
    $display("ALU_SRA");
    rs1 = 32'hbadcaffe;
    rs2 = 4;
    #2;
    rs1 = 32'ha5a5a5a5;
    rs2 = 1;
    #2;
    rs1 = 32'ha5a5a5a5;
    rs2 = -1;
    #2;
    $finish;
  end

  alu #(.WIDTH(`WIDTH)) u_dut (
    .rs1(rs1),
    .rs2(rs2),
    .rd(rd),
    .op(op)
  );
endmodule
