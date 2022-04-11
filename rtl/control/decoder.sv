/*
 * Decoder
 *
 * Decode RV32G instructions.
 *
 * 2022 04 10
 */

`include "datatypes.sv"

module ir_decoder (
  input logic [31:0] ir,
  output logic [2:0] instr_type,
  output logic [6:0] opcode,
  output logic [4:0] rs1,
  output logic [4:0] rs2,
  output logic [4:0] rd,
  output logic [6:0] funct7,
  output logic [2:0] funct3,
  output logic [3:0] fm,
  output logic [3:0] pred,
  output logic [3:0] succ,
  output logic [31:0] immediate
);

assign funct7 = ir[31:25];
assign funct3 = ir[14:12];
assign rs1 = ir[19:15];
assign rs2 = ir[24:20];
assign rd = ir[11:7];
assign fm = ir[31:28];
assign pred = ir[27:24];
assign succ = ir[23:20];
assign opcode = ir[6:0];

always_comb begin
  instr_type=0;
  // U-TYPE
  if ((opcode==LUI)||(opcode==AUIPC)) begin
    instr_type = INSTR_U;
  end
  // J-TYPE
  if (opcode==JAL) begin
    instr_type = INSTR_J;
  end
  if ((opcode==LUI)||(opcode==AUIPC)) begin

  end
end


endmodule : ir_decoder 
