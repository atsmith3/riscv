/* datatypes.sv
*/

`ifndef __DATATYPES_SV__
`define __DATATYPES_SV__

typedef enum bit [1:0] {
  DATABUS_PC=0,
  DATABUS_MDR,
  DATABUS_ALU
} databus_mux_sel_t;

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

`endif
