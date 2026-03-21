/* mux4.sv
 *
 * Multiplexer modules for the RISC-V 32I processor
 *
 * This file contains multiplexer implementations used throughout the datapath
 * for routing signals between various components.
 *
 * Multiplexers are used to:
 *   - Select ALU operands (RS1, RS2)
 *   - Select databus source (PC, ALU, MDR, CSR, etc.)
 *   - Select MDR source (load data vs. databus)
 *
 * All multiplexers are parameterized by WIDTH to support different bit widths.
 */

// ============================================================================
// 2:1 Multiplexer
// ============================================================================
// Selects between two inputs based on a single-bit select signal
// Used as building block for larger multiplexers
module mux2
    #(parameter WIDTH = 32)
    (input logic [WIDTH - 1 : 0] a,
     // Input A
     input logic [WIDTH - 1 : 0] b,
     // Input B
     input logic sel,
     // Select signal (0=A, 1=B)
     output logic [WIDTH - 1 : 0] y // Output
    );

  always_comb begin
    y = a;
    if (sel) begin
      y = b;
    end
  end

endmodule : mux2

// ============================================================================
// 4:1 Multiplexer
// ============================================================================
// Selects between four inputs using a 2-bit select signal
// Implemented using two cascaded 2:1 multiplexers
module mux4
    #(parameter WIDTH = 32)
    (input logic [WIDTH - 1 : 0] a,
     // Input A (sel=00)
     input logic [WIDTH - 1 : 0] b,
     // Input B (sel=01)
     input logic [WIDTH - 1 : 0] c,
     // Input C (sel=10)
     input logic [WIDTH - 1 : 0] d,
     // Input D (sel=11)
     input logic [1 : 0] sel,
     // Select signal
     output logic [WIDTH - 1 : 0] y // Output
    );

  logic [WIDTH - 1 : 0] n1, n2;

  // First level: select between (a,b) and (c,d)
  mux2 u_mux_0(.a(a),
               .b(b),
               .sel(sel[0]),
               .y(n1));

  mux2 u_mux_1(.a(c),
               .b(d),
               .sel(sel[0]),
               .y(n2));

  // Second level: select between results of first level
  mux2 u_mux_2(.a(n1),
               .b(n2),
               .sel(sel[1]),
               .y(y));

endmodule : mux4

// ============================================================================
// 8:1 Multiplexer
// ============================================================================
// Selects between eight inputs using a 3-bit select signal
// Implemented using cascaded 4:1 and 2:1 multiplexers
module mux8
    #(parameter WIDTH = 32)
    (input logic [WIDTH - 1 : 0] a,
     // Input A (sel=000)
     input logic [WIDTH - 1 : 0] b,
     // Input B (sel=001)
     input logic [WIDTH - 1 : 0] c,
     // Input C (sel=010)
     input logic [WIDTH - 1 : 0] d,
     // Input D (sel=011)
     input logic [WIDTH - 1 : 0] e,
     // Input E (sel=100)
     input logic [WIDTH - 1 : 0] f,
     // Input F (sel=101)
     input logic [WIDTH - 1 : 0] g,
     // Input G (sel=110)
     input logic [WIDTH - 1 : 0] h,
     // Input H (sel=111)
     input logic [2 : 0] sel,
     // Select signal
     output logic [WIDTH - 1 : 0] y // Output
    );

  logic [WIDTH - 1 : 0] n1, n2;

  // First level: two 4:1 multiplexers
  mux4 u_mux_0(.a(a),
               .b(b),
               .c(c),
               .d(d),
               .sel(sel[1 : 0]),
               .y(n1));

  mux4 u_mux_1(.a(e),
               .b(f),
               .c(g),
               .d(h),
               .sel(sel[1 : 0]),
               .y(n2));

  // Second level: 2:1 multiplexer
  mux2 u_mux_2(.a(n1),
               .b(n2),
               .sel(sel[2]),
               .y(y));

endmodule : mux8
