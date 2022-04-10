/* 
 * Branch Eval
 * 2022 04 10
 */

`include "datatypes.sv"

module branch_eval #(parameter WIDTH = 32) (
  input logic [WIDTH-1:0] rs1,
  input logic [WIDTH-1:0] rs2,
  input logic [2:0] func,
  output logic branch,
  output logic exception
);

always_comb begin
  branch = 0;
  exception = 0;
  case (func)
    BEQ: begin
      branch = (rs1 == rs2) ? 1'b1 : 1'b0;
    end
    BNE: begin
      branch = (rs1 != rs2) ? 1'b1 : 1'b0;
    end
    BLT: begin
      branch = ($signed(rs1) < $signed(rs2)) ? 1'b1 : 1'b0;
    end
    BGE: begin
      branch = ($signed(rs1) >= $signed(rs2)) ? 1'b1 : 1'b0;
    end
    BLTU: begin
      branch = (rs1 < rs2) ? 1'b1 : 1'b0;
    end
    BGEU: begin
      branch = (rs1 >= rs2) ? 1'b1 : 1'b0;
    end
    BRANCH_RESERVED_1,
    BRANCH_RESERVED_2: begin
      exception = 1'b1;
    end
    default: begin

    end
  endcase
end

endmodule : branch_eval
