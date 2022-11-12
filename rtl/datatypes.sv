/* datatypes.sv
*/

`ifndef __DATATYPES_SV__
`define __DATATYPES_SV__

typedef enum bit [1:0] {
  DATABUS_PC=0,
  DATABUS_ALU,
  DATABUS_MDR,
  DATABUS_MAR
} databus_mux_sel_t;

typedef enum bit [1:0] {
  RS2_PC=0,
  RS2_ALU,
  RS2_MDR,
  RS2_MAR
} rs2_mux_sel_t;

typedef enum bit [3:0] {
  ALU_ADD=0,
  ALU_SLL,
  ALU_SLT,
  ALU_SLTU,
  ALU_XOR,
  ALU_SRL,
  ALU_OR,
  ALU_AND,
  ALU_SUB,
  ALU_SRA=13
} alu_op_t;

typedef enum bit [2:0] {
  BEQ=0,
  BNE,
  BRANCH_RESERVED_1,
  BRANCH_RESERVED_2,
  BLT,
  BGE,
  BLTU,
  BGEU
} branch_t;

typedef enum bit [2:0] {
  INSTR_R,
  INSTR_I,
  INSTR_S,
  INSTR_B,
  INSTR_U,
  INSTR_J
} instr_format_t;

typedef enum bit [6:0] {
  LUI    = 7'b0110111,
  AUIPC  = 7'b0010111,
  JAL    = 7'b1101111,
  JALR   = 7'b1100111,
  BRANCH = 7'b1100011,
  LD     = 7'b0000011,
  ST     = 7'b0100011,
  ALUI   = 7'b0010011,
  ALU    = 7'b0110011,
  FENCE  = 7'b0001111,
  ECSR   = 7'b1110011
} opcode_t;

`endif
