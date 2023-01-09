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
  output logic [1:0] databus_mux_sel,
  output logic mem_write,
  output logic mem_read,
  input logic mem_resp
);

  enum {
    FETCH_0 = 0,                  // MAR <- PC; PC <- PC+1
    FETCH_1,                      // wait on mem
    FETCH_2,                      // MDR <- M[MAR]
    FETCH_3,                      // IR <- MDR
    DECODE                        // Dispatch based on OpCode
  } state, next_state;

  always_ff @ (posedge clk) begin
    if (!rst_n) begin
      state <= FETCH_0;
    end
    else begin
      state <= next_state;
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
    endcase
  end
endmodule
