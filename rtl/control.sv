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
  output logic load_bsr,
  output logic pc_mux_sel,
  output logic mdr_mux_sel,
  output logic [3:0] alu_op,
  output logic [1:0] databus_mux_sel,
  output logic mem_write,
  output logic mem_read,
  input logic mem_resp,
  input logic [31:0] ir,
  input logic [31:0] rs1,
  input logic [31:0] rs2,
  output logic [31:0] immediate
);

  logic [2:0] instr_type;
  logic [6:0] opcode;
  logic [4:0] rs1;
  logic [4:0] rs2;
  logic [4:0] rd;
  logic [6:0] funct7;
  logic [2:0] funct3;
  logic [3:0] fm;
  logic [3:0] pred;
  logic [3:0] succ;
  logic arithmatic;
  logic ebreak;
  logic [31:0] immediate;
  logic branch;

  enum {
    FETCH_0 = 0,                  // MAR <- PC; PC <- PC+1
    FETCH_1,                      // wait on mem
    FETCH_2,                      // MDR <- M[MAR]
    FETCH_3,                      // IR <- MDR
    DECODE,                       // Dispatch based on OpCode
    BRANCH,
    BRANCH_T,
    BRANCH_N,
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

  always_comb begin
    alu_op = {1'b0,funct3};
    if (opcode==ALUI && (funct3 == 3'b001 || funct3 == 3'b101)) begin
      alu_op = {arithmatic,funct3};
    end
  end

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
      FETCH_2 : begin
        next_state = FETCH_0;
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
    load_bsr = 1'b0;
    pc_mux_sel = 0;
    mdr_mux_sel = 0;
    databus_mux_sel = DATABUS_PC;
    mem_read = 0;
    mem_write = 0;

    case (state)
      FETCH_0: begin
        load_mar = 1'b1;
        load_pc = 1'b1;
        mem_read = 1'b1;
      end
      FETCH_1: begin
        mem_read = 1'b1;
      end
      FETCH_2: begin
        mem_read = 1'b1;
        load_mdr = 1'b1;
      end
      FETCH_3: begin
        load_ir = 1'b1;
        databus_mux_sel = DATABUS_MDR;
      end
      DECODE: begin

      end
    endcase
  end
endmodule
