/* control.sv
 *
 */

`include "datatypes.sv"

module control
(
  input logic clk,
  input logic rst_n,
  output logic load_mar,
  output logic load_pc,
  output logic load_ir,
  output logic load_mdr,
  output logic load_reg,
  output logic pc_mux_sel,
  output logic mdr_mux_sel,
  output rs1_mux_sel_t  rs1_mux_sel,
  output rs2_mux_sel_t  rs2_mux_sel,
  output logic [3:0] alu_op,
  output databus_mux_sel_t databus_mux_sel,
  output logic mem_write,
  output logic mem_read,
  output logic [4:0] rs1,
  output logic [4:0] rs2,
  output logic [4:0] rd,
  input logic mem_resp,
  input logic [2:0] bsr,
  input logic [31:0] ir,
  input logic [31:0] rs1_val,
  input logic [31:0] rs2_val,
  output logic [31:0] immediate
);

  logic [2:0] instr_type;
  logic [6:0] opcode;
  logic [6:0] funct7;
  logic [2:0] funct3;
  logic [3:0] fm;
  logic [3:0] pred;
  logic [3:0] succ;
  logic arithmatic;
  logic ebreak;
  logic branch;
  logic beq, blt, bltu;

  assign beq = bsr[2];
  assign blt = bsr[1];
  assign bltu = bsr[0];

  enum {
    FETCH_0 = 0,                  // MAR <- PC
    FETCH_1,                      // wait on mem
    FETCH_2,                      // MDR <- M[MAR]
    FETCH_3,                      // IR <- MDR
    DECODE,                       // Dispatch based on OpCode
    BRANCH_0,                     // Determine if Branch Taken/Not Taken
    BRANCH_T,                     // PC <- PC + IMM
    PC_INC,                       // PC <- PC + 4
    JAL_0,                        // RD <- PC + 4
    JAL_1,                        // PC <- PC + IMM
    REG_REG,                      // RD <- RS1 op RS2
    REG_IMM,                      // RD <- RS1 op IMM
    LUI_0,                        // RD <- IMM
    JALR_0,                       // RD <- PC + 4
    JALR_1,                       // PC <- RS1 + IMM
    LD_0,                         // MAR <- RS1 + IMM
    LD_1,                         
    LD_2,
    LD_3,                         // MDR <- M[MAR]
    LD_4,                         // RD <- MDR
    ST_0,                         // MAR <- RS1 + IMM
    ST_1,                         // MDR <- RS2
    ST_2,
    ST_3,                         // M[MAR] <- MDR
    AUIPC_0,                      // RD <- PC + IMM
    ERROR_INVALID_OPCODE,
    ERROR_OPCODE_NOT_IMPLEMENTED
  } state, next_state;

  always_ff @ (posedge clk) begin
    if (!rst_n) begin
      state <= FETCH_0;
    end
    else begin
      state <= next_state;
    end
  end

  ir_decoder u_ir_decoder (
    .ir(ir),
    .instr_type(instr_type),
    .opcode(opcode),
    .rs1(rs1),
    .rs2(rs2),
    .rd(rd),
    .funct7(funct7),
    .funct3(funct3),
    .fm(fm),
    .pred(pred),
    .succ(succ),
    .arithmatic(arithmatic),
    .ebreak(ebreak),
    .immediate(immediate));


  // Next State Logic
  always_comb begin
    // Defaults
    next_state = FETCH_0;

    case (state)
      FETCH_0 : begin
        next_state = FETCH_1;
      end
      FETCH_1 : begin
        next_state = FETCH_1;
        if (mem_resp) begin
          next_state = FETCH_2;
        end
      end
      FETCH_2 : begin
        next_state = FETCH_3;
      end
      FETCH_3 : begin
        next_state = DECODE;
      end
      DECODE : begin                       // Dispatch based on OpCode
        next_state = ERROR_INVALID_OPCODE;
        case (opcode)
          LUI : begin
            next_state = LUI_0;
          end
          AUIPC : begin
            next_state = AUIPC_0;
          end
          JAL : begin
            next_state = JAL_0;
          end
          JALR : begin
            next_state = JALR_0;
          end
          BRANCH : begin
            next_state = BRANCH_0;
          end
          LD : begin
            next_state = LD_0;
          end
          ST : begin
            next_state = ST_0;
          end
          ALUI : begin
            next_state = REG_IMM;
          end
          ALU : begin
            next_state = REG_REG;
          end
          FENCE : begin
            next_state = ERROR_OPCODE_NOT_IMPLEMENTED;
          end
          ECSR : begin
            next_state = ERROR_OPCODE_NOT_IMPLEMENTED;
          end
        endcase
      end
      BRANCH_0 : begin                       // Determine if Branch Taken/Not Taken
        next_state = PC_INC;
        case (funct3)
          BEQ : begin
            if ( beq ) next_state = BRANCH_T;
          end
          BNE : begin
            if ( ~beq ) next_state = BRANCH_T;
          end
          BLT : begin
            if ( blt ) next_state = BRANCH_T;
          end
          BGE : begin
            if ( ~blt ) next_state = BRANCH_T;
          end
          BLTU : begin
            if ( bltu ) next_state = BRANCH_T;
          end
          BGEU : begin
            if ( ~bltu ) next_state = BRANCH_T;
          end
          default : begin
          end
        endcase
      end
      BRANCH_T : begin                     // PC <- PC + IMM
        next_state = FETCH_0;
      end
      PC_INC : begin                       // PC <- PC + 4
        next_state = FETCH_0;
      end
      JAL_0 : begin                          // RD <- PC + 4
        next_state = JAL_1;
      end
      JAL_1 : begin                          // PC <- PC + IMM
        next_state = FETCH_0;
      end
      REG_REG : begin                      // RD <- RS1 op RS2
        next_state = PC_INC;
      end
      REG_IMM : begin                      // RD <- RS1 op IMM
        next_state = PC_INC;
      end
      LUI_0 : begin                          // RD <- IMM
        next_state = PC_INC;
      end
      JALR_0 : begin                         // RD <- PC + 4
        next_state = JALR_1;
      end
      JALR_1 : begin                         // PC <- RS1 + IMM
        next_state = FETCH_0;
      end
      LD_0 : begin                         // MAR <- RS1 + IMM
        next_state = LD_1;
      end
      LD_1 : begin                         
        next_state = LD_2;
      end
      LD_2 : begin
        next_state = LD_2;
        if (mem_resp) begin
          next_state = LD_3;
        end
      end
      LD_3 : begin                         // MDR <- M[MAR]
        next_state = LD_4;
      end
      LD_4 : begin                         // RD <- MDR
        next_state = PC_INC;
      end
      ST_0 : begin                         // MAR <- RS1 + IMM
        next_state = ST_1;
      end
      ST_1 : begin                         // MDR <- RS2
        next_state = ST_2;
      end
      ST_2 : begin
        next_state = ST_3;
      end
      ST_3 : begin                         // M[MAR] <- MDR
        next_state = ST_3;
        if (mem_resp) begin
          next_state = PC_INC;
        end
      end
      AUIPC_0 : begin                      // RD <- PC + IMM
        next_state = PC_INC;
      end
      ERROR_INVALID_OPCODE : begin
        // Catch CPU Here
        next_state = ERROR_INVALID_OPCODE;
      end
      ERROR_OPCODE_NOT_IMPLEMENTED : begin
        // Catch CPU Here
        next_state = ERROR_OPCODE_NOT_IMPLEMENTED;
      end
      default:
        next_state = FETCH_0;
    endcase
  end

  // Output Logic
  always_comb begin
    // Defaults
    load_mar = 1'b0;
    load_mdr = 1'b0;
    load_pc = 1'b0;
    load_ir = 1'b0;
    load_reg = 1'b0;
    pc_mux_sel = 0;
    mdr_mux_sel = 0;
    databus_mux_sel = DATABUS_PC;
    rs1_mux_sel = RS1_OUT;
    rs2_mux_sel = RS2_OUT;
    mem_read = 0;
    mem_write = 0;
    alu_op = ALU_ADD;

    case (state)
      FETCH_0: begin
        load_mar = 1'b1;
        mem_read = 1'b1;
      end
      FETCH_1: begin
      end
      FETCH_2: begin
        load_mdr = 1'b1;
      end
      FETCH_3: begin
        load_ir = 1'b1;
        databus_mux_sel = DATABUS_MDR;
      end
      DECODE: begin

      end
      BRANCH_0 : begin
      end
      BRANCH_T : begin
        load_pc = 1'b1;
        databus_mux_sel = DATABUS_ALU;
        rs1_mux_sel = RS1_PC;
        rs2_mux_sel = RS2_IMM;
      end
      PC_INC : begin
        load_pc = 1'b1;
        databus_mux_sel = DATABUS_ALU;
        rs1_mux_sel = RS1_4;
        rs2_mux_sel = RS2_PC;
      end
      JAL_0 : begin
        load_reg = 1'b1;
        databus_mux_sel = DATABUS_ALU;
        rs1_mux_sel = RS1_4;
        rs2_mux_sel = RS2_PC;
      end
      JAL_1 : begin
        load_pc = 1'b1;
        databus_mux_sel = DATABUS_ALU;
        rs1_mux_sel = RS1_PC;
        rs2_mux_sel = RS2_IMM;
      end
      REG_REG : begin
        databus_mux_sel = DATABUS_ALU;
        load_reg = 1'b1;
        alu_op = {1'b0,funct3};
        if (funct3 == 3'b001 || funct3 == 3'b101 || funct3 == 3'b000) begin
          alu_op = {arithmatic,funct3};
        end
      end
      REG_IMM : begin
        databus_mux_sel = DATABUS_ALU;
        rs2_mux_sel = RS2_IMM;
        load_reg = 1'b1;
        alu_op = {1'b0,funct3};
        if (funct3 == 3'b001 || funct3 == 3'b101) begin
          alu_op = {arithmatic,funct3};
        end
      end
      LUI_0 : begin
        load_reg = 1'b1;
        rs2_mux_sel = RS2_IMM;
        databus_mux_sel = DATABUS_ALU;
        alu_op = ALU_PASS_RS2;
      end
      JALR_0 : begin
        load_reg = 1'b1;
        databus_mux_sel = DATABUS_ALU;
        rs1_mux_sel = RS1_4;
        rs2_mux_sel = RS2_PC;
      end
      JALR_1 : begin
        load_pc = 1'b1;
        rs2_mux_sel = RS2_IMM;
        databus_mux_sel = DATABUS_ALU;
      end
      LD_0 : begin
        load_mar = 1'b1;
        databus_mux_sel = DATABUS_ALU;
        rs2_mux_sel = RS2_IMM;
      end
      LD_1 : begin
        mem_read = 1'b1;
      end
      LD_2 : begin
      end
      LD_3 : begin
        load_mdr = 1'b1;
      end
      LD_4 : begin
        databus_mux_sel = DATABUS_MDR;
        load_reg = 1'b1;
      end
      ST_0 : begin
        load_mar = 1'b1;
        databus_mux_sel = DATABUS_ALU;
        rs2_mux_sel = RS2_IMM;
      end
      ST_1 : begin
        load_mdr = 1'b1;
        databus_mux_sel = DATABUS_ALU;
        mdr_mux_sel = 1'b1;
        alu_op = ALU_PASS_RS2;
      end
      ST_2 : begin
        mem_write = 1'b1;
      end
      ST_3 : begin
      end
      AUIPC_0 : begin
        load_reg = 1'b1;
        rs2_mux_sel = RS2_IMM;
        rs1_mux_sel = RS1_PC;
        databus_mux_sel = DATABUS_ALU;
      end
    endcase
  end
endmodule
