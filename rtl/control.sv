/* control.sv
 *
 * Control unit for the RISC-V 32I processor
 *
 * This module implements the control FSM that orchestrates all processor
 * operations. It decodes instructions and generates control signals for
 * the datapath components during each cycle of instruction execution.
 *
 * FSM States:
 *   - FETCH_0-3: Four-cycle instruction fetch sequence
 *   - DECODE: Instruction decode and dispatch
 *   - Execution states for each instruction type (REG_REG, REG_IMM, etc.)
 *   - Branch/jump states (BRANCH_0, BRANCH_T, JAL, JALR)
 *   - Memory access states (LD_0-4, ST_0-3)
 *   - PC_INC: Increment PC by 4
 *   - Error states for invalid/unimplemented instructions
 *
 * Control Signals Generated:
 *   - Register load enables (load_pc, load_ir, load_mar, load_mdr, load_reg)
 *   - Multiplexer selects (rs1_mux_sel, rs2_mux_sel, databus_mux_sel, mdr_mux_sel)
 *   - ALU operation select (alu_op)
 *   - Memory interface signals (mem_read, mem_write)
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
  output logic mdr_mux_sel,
  output rs1_mux_sel_t  rs1_mux_sel,
  output rs2_mux_sel_t  rs2_mux_sel,
  output alu_op_t alu_op,
  output databus_mux_sel_t databus_mux_sel,
  output logic mem_write,
  output logic mem_read,
  output mem_size_t mem_size,
  output logic load_unsigned,
  output logic [4:0] rs1,
  output logic [4:0] rs2,
  output logic [4:0] rd,
  input logic mem_resp,
  input logic [2:0] bsr,
  input logic [31:0] ir,
  input logic [31:0] rs1_val,
  input logic [31:0] rs2_val,
  output logic [31:0] immediate,
  // CSR interface
  output logic csr_access,       // High when accessing CSR
  output logic csr_write,         // High when writing to CSR (for instret increment)
  input logic csr_valid           // CSR address valid signal
);

  logic [2:0] instr_type;
  logic [6:0] opcode;
  logic [6:0] funct7;
  logic [2:0] funct3;
  logic [3:0] fm;
  logic [3:0] pred;
  logic [3:0] succ;
  logic arithmetic;
  logic ebreak;
  logic branch;
  logic beq, blt, bltu;

  assign beq = bsr[2];
  assign blt = bsr[1];
  assign bltu = bsr[0];

  // FSM State Definitions
  // Each instruction execution is broken into multiple states for the multi-cycle design
  enum {
    // Instruction Fetch Sequence (4 cycles)
    FETCH_0 = 0,                  // MAR <- PC, initiate memory read
    FETCH_1,                      // Wait for memory response
    FETCH_2,                      // MDR <- M[MAR] (capture instruction)
    FETCH_3,                      // IR <- MDR (load instruction register)

    // Decode and Dispatch
    DECODE,                       // Decode instruction and dispatch to appropriate state

    // Branch Instructions
    BRANCH_0,                     // Evaluate branch condition (BEQ, BNE, BLT, BGE, BLTU, BGEU)
    BRANCH_T,                     // Branch taken: PC <- PC + IMM

    // Common States
    PC_INC,                       // PC <- PC + 4 (advance to next instruction)

    // Jump Instructions
    JAL_0,                        // JAL: RD <- PC + 4 (save return address)
    JAL_1,                        // JAL: PC <- PC + IMM (jump to target)

    // ALU Instructions
    REG_REG,                      // R-type: RD <- RS1 op RS2 (register-register operations)
    REG_IMM,                      // I-type: RD <- RS1 op IMM (register-immediate operations)

    // Upper Immediate Instructions
    LUI_0,                        // LUI: RD <- IMM (load upper immediate)
    AUIPC_0,                      // AUIPC: RD <- PC + IMM (add upper immediate to PC)

    // Jump and Link Register
    JALR_0,                       // JALR: RD <- PC + 4 (save return address)
    JALR_1,                       // JALR: PC <- RS1 + IMM (jump to computed address)

    // Load Instructions (Memory Read)
    LD_0,                         // MAR <- RS1 + IMM (compute memory address)
    LD_1,                         // Initiate memory read
    LD_2,                         // Wait for memory response
    LD_3,                         // MDR <- M[MAR] (capture loaded data)
    LD_4,                         // RD <- MDR (write to destination register)

    // Store Instructions (Memory Write)
    ST_0,                         // MAR <- RS1 + IMM (compute memory address)
    ST_1,                         // MDR <- RS2 (prepare data to store)
    ST_2,                         // Initiate memory write
    ST_3,                         // Wait for memory write completion

    // CSR Instructions
    CSR_0,                        // Read CSR, compute new value
    CSR_1,                        // Write old CSR value to RD, update CSR

    // Error States
    ERROR_INVALID_OPCODE,         // Invalid instruction opcode detected
    ERROR_OPCODE_NOT_IMPLEMENTED  // Valid but unimplemented instruction (CSR, FENCE, etc.)
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
    .arithmetic(arithmetic),
    .ebreak(ebreak),
    .immediate(immediate));


  // Next State Logic
  // Determines the next FSM state based on current state and instruction type
  always_comb begin
    // Default: Return to fetch on completion or error
    next_state = FETCH_0;

    case (state)
      // ==== INSTRUCTION FETCH SEQUENCE ====
      // Four-cycle sequence to fetch instruction from memory
      FETCH_0 : begin
        next_state = FETCH_1;  // Always proceed to wait state
      end
      FETCH_1 : begin
        next_state = FETCH_1;  // Wait here until memory responds
        if (mem_resp) begin
          next_state = FETCH_2;  // Memory ready, capture data
        end
      end
      FETCH_2 : begin
        next_state = FETCH_3;  // Data captured in MDR, load IR next
      end
      FETCH_3 : begin
        next_state = DECODE;  // IR loaded, proceed to decode
      end

      // ==== DECODE AND DISPATCH ====
      // Examine opcode and branch to appropriate execution sequence
      DECODE : begin
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
            // Distinguish CSR instructions (funct3 != 0) from ECALL/EBREAK (funct3 == 0)
            if (funct3 == 3'b000) begin
              next_state = ERROR_OPCODE_NOT_IMPLEMENTED;  // ECALL/EBREAK not implemented yet
            end else begin
              next_state = CSR_0;  // CSR instruction
            end
          end
          default : begin
            next_state = ERROR_OPCODE_NOT_IMPLEMENTED;
          end
        endcase
      end
      // ==== BRANCH INSTRUCTIONS ====
      // Evaluate condition and branch if taken
      BRANCH_0 : begin
        next_state = PC_INC;  // Default: branch not taken, increment PC
        case (funct3)
          BEQ : begin
            if ( beq ) next_state = BRANCH_T;  // Branch if equal
          end
          BNE : begin
            if ( ~beq ) next_state = BRANCH_T;  // Branch if not equal
          end
          BLT : begin
            if ( blt ) next_state = BRANCH_T;  // Branch if less than (signed)
          end
          BGE : begin
            if ( ~blt ) next_state = BRANCH_T;  // Branch if greater/equal (signed)
          end
          BLTU : begin
            if ( bltu ) next_state = BRANCH_T;  // Branch if less than (unsigned)
          end
          BGEU : begin
            if ( ~bltu ) next_state = BRANCH_T;  // Branch if greater/equal (unsigned)
          end
          default : begin
          end
        endcase
      end
      BRANCH_T : begin  // Branch taken: update PC and return to fetch
        next_state = FETCH_0;
      end

      // ==== COMMON STATES ====
      PC_INC : begin  // Increment PC by 4, return to fetch
        next_state = FETCH_0;
      end

      // ==== JUMP AND LINK (JAL) ====
      JAL_0 : begin  // Save return address (PC+4) to rd
        next_state = JAL_1;
      end
      JAL_1 : begin  // Update PC with target address, return to fetch
        next_state = FETCH_0;
      end

      // ==== REGISTER-REGISTER ALU OPERATIONS ====
      REG_REG : begin  // R-type: Compute result and write to rd, then increment PC
        next_state = PC_INC;
      end

      // ==== REGISTER-IMMEDIATE ALU OPERATIONS ====
      REG_IMM : begin  // I-type: Compute result and write to rd, then increment PC
        next_state = PC_INC;
      end

      // ==== LOAD UPPER IMMEDIATE ====
      LUI_0 : begin  // Load immediate into rd, then increment PC
        next_state = PC_INC;
      end

      // ==== ADD UPPER IMMEDIATE TO PC ====
      AUIPC_0 : begin  // Compute PC+imm and write to rd, then increment PC
        next_state = PC_INC;
      end

      // ==== JUMP AND LINK REGISTER (JALR) ====
      JALR_0 : begin  // Save return address (PC+4) to rd
        next_state = JALR_1;
      end
      JALR_1 : begin  // Update PC with computed address (rs1+imm), return to fetch
        next_state = FETCH_0;
      end

      // ==== LOAD WORD ====
      // Multi-cycle memory read sequence
      LD_0 : begin  // Compute effective address (rs1+imm)
        next_state = LD_1;
      end
      LD_1 : begin  // Initiate memory read
        next_state = LD_2;
      end
      LD_2 : begin  // Wait for memory response
        next_state = LD_2;
        if (mem_resp) begin
          next_state = LD_3;  // Memory ready, capture data
        end
      end
      LD_3 : begin  // Data captured in MDR
        next_state = LD_4;
      end
      LD_4 : begin  // Write data from MDR to rd, then increment PC
        next_state = PC_INC;
      end

      // ==== STORE WORD ====
      // Multi-cycle memory write sequence
      ST_0 : begin  // Compute effective address (rs1+imm)
        next_state = ST_1;
      end
      ST_1 : begin  // Prepare data from rs2 in MDR
        next_state = ST_2;
      end
      ST_2 : begin  // Initiate memory write
        next_state = ST_3;
      end
      ST_3 : begin  // Wait for memory write completion
        next_state = ST_3;
        if (mem_resp) begin
          next_state = PC_INC;  // Write complete, increment PC
        end
      end

      // ==== CSR INSTRUCTIONS ====
      // Atomic read-modify-write for Control and Status Registers
      CSR_0 : begin  // Read CSR, compute new value
        if (!csr_valid) begin
          next_state = ERROR_OPCODE_NOT_IMPLEMENTED;  // Invalid CSR address
        end else begin
          next_state = CSR_1;
        end
      end
      CSR_1 : begin  // Write old CSR value to rd, update CSR
        next_state = PC_INC;
      end

      // ==== ERROR STATES ====
      ERROR_INVALID_OPCODE : begin
        next_state = ERROR_INVALID_OPCODE;  // Halt: invalid opcode
      end
      ERROR_OPCODE_NOT_IMPLEMENTED : begin
        next_state = ERROR_OPCODE_NOT_IMPLEMENTED;  // Halt: unimplemented instruction
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
    mdr_mux_sel = 0;
    databus_mux_sel = DATABUS_PC;
    rs1_mux_sel = RS1_OUT;
    rs2_mux_sel = RS2_OUT;
    mem_read = 0;
    mem_write = 0;
    alu_op = ALU_ADD;
    csr_access = 1'b0;
    csr_write = 1'b0;

    // Suppress outputs during reset
    if (!rst_n) begin
      load_mar = 1'b0;
      load_mdr = 1'b0;
      load_pc = 1'b0;
      load_ir = 1'b0;
      load_reg = 1'b0;
      mem_read = 1'b0;
      mem_write = 1'b0;
    end
    else begin
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
        /*
        alu_op = {1'b0,funct3};
        if (funct3 == 3'b001 || funct3 == 3'b101 || funct3 == 3'b000) begin
          alu_op = {arithmetic,funct3};
        end
        */
        case(funct3)
          3'b000:begin
            if(arithmetic) begin
              alu_op = ALU_SUB;
            end
            else begin
              alu_op = ALU_ADD;
            end
          end
          3'b001:begin
            if(arithmetic) begin
              alu_op = ALU_PASS_RS1;
            end
            else begin
              alu_op = ALU_SLL;
            end
          end
          3'b010:begin
            alu_op = ALU_SLT;
          end
          3'b011:begin
            alu_op = ALU_SLTU;
          end
          3'b100:begin
            alu_op = ALU_XOR;
          end
          3'b101:begin
            if(arithmetic) begin
              alu_op = ALU_SRA;
            end
            else begin
              alu_op = ALU_SRL;
            end
          end
          3'b110: alu_op = ALU_OR;
          3'b111: alu_op = ALU_AND;
        endcase
      end
      REG_IMM : begin
        databus_mux_sel = DATABUS_ALU;
        rs2_mux_sel = RS2_IMM;
        load_reg = 1'b1;
        /*
        alu_op = {1'b0,funct3};
        if (funct3 == 3'b001 || funct3 == 3'b101) begin
          alu_op = {arithmetic,funct3};
        end
        */
        case(funct3)
          3'b000:begin
            alu_op = ALU_ADD;
          end
          3'b001:begin
            if(arithmetic) begin
              alu_op = ALU_PASS_RS1;
            end
            else begin
              alu_op = ALU_SLL;
            end
          end
          3'b010:begin
            alu_op = ALU_SLT;
          end
          3'b011:begin
            alu_op = ALU_SLTU;
          end
          3'b100:begin
            alu_op = ALU_XOR;
          end
          3'b101:begin
            if(arithmetic) begin
              alu_op = ALU_SRA;
            end
            else begin
              alu_op = ALU_SRL;
            end
          end
          3'b110:begin
            alu_op = ALU_OR;
          end
          3'b111:begin
            alu_op = ALU_AND;
          end
        endcase
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
      CSR_0 : begin
        // Read CSR and compute new value
        // CSR read data will be captured and used in CSR_1
        csr_access = 1'b1;
      end
      CSR_1 : begin
        // Write old CSR value to rd
        // CSR module handles the actual register write
        load_reg = 1'b1;
        databus_mux_sel = DATABUS_CSR;
        csr_access = 1'b1;
        csr_write = 1'b1;
      end
      AUIPC_0 : begin
        load_reg = 1'b1;
        rs2_mux_sel = RS2_IMM;
        rs1_mux_sel = RS1_PC;
        databus_mux_sel = DATABUS_ALU;
      end
      endcase
    end  // end else (not in reset)
  end  // end always_comb

  // Decode funct3 for memory size and sign extension
  always_comb begin
    // Default values
    mem_size = MEM_SIZE_WORD;
    load_unsigned = 1'b0;

    // CRITICAL: During FETCH states, always use WORD size for instruction fetch
    // This prevents corruption of instruction fetches by byte/halfword load settings
    // from previous data load instructions
    if (state == FETCH_0 || state == FETCH_1 || state == FETCH_2 || state == FETCH_3) begin
      mem_size = MEM_SIZE_WORD;
      load_unsigned = 1'b0;
    end
    // Only decode for load/store operations during data memory access
    else if (opcode == LD) begin
      case (funct3)
        3'b000: begin  // LB - load byte (signed)
          mem_size = MEM_SIZE_BYTE;
          load_unsigned = 1'b0;
        end
        3'b001: begin  // LH - load halfword (signed)
          mem_size = MEM_SIZE_HALF;
          load_unsigned = 1'b0;
        end
        3'b010: begin  // LW - load word
          mem_size = MEM_SIZE_WORD;
          load_unsigned = 1'b0;
        end
        3'b100: begin  // LBU - load byte unsigned
          mem_size = MEM_SIZE_BYTE;
          load_unsigned = 1'b1;
        end
        3'b101: begin  // LHU - load halfword unsigned
          mem_size = MEM_SIZE_HALF;
          load_unsigned = 1'b1;
        end
        default: begin
          mem_size = MEM_SIZE_WORD;
          load_unsigned = 1'b0;
        end
      endcase
    end else if (opcode == ST) begin
      case (funct3)
        3'b000: begin  // SB - store byte
          mem_size = MEM_SIZE_BYTE;
        end
        3'b001: begin  // SH - store halfword
          mem_size = MEM_SIZE_HALF;
        end
        3'b010: begin  // SW - store word
          mem_size = MEM_SIZE_WORD;
        end
        default: begin
          mem_size = MEM_SIZE_WORD;
        end
      endcase
    end
  end

endmodule
