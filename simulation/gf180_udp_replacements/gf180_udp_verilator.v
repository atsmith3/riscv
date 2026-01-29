// Replacements for GF180 UDP primitives compatible with Verilator
// These modules replace the UDP-based flip-flops and latches that Verilator cannot simulate.
// The N (notifier) input is ignored - it's used for timing violation modeling only.

// gf180mcu_fd_sc_mcu9t5v0__udp_n_iq_ff - D flip-flop (clear priority)
module gf180mcu_fd_sc_mcu9t5v0__udp_n_iq_ff(Q, C, P, CK, D, N);
output reg Q;
input C, P, CK, D, N;
    always @(posedge CK or posedge C or posedge P) begin
        if (C)       Q <= 1'b0;  // Clear priority
        else if (P)  Q <= 1'b1;  // Preset
        else         Q <= D;     // Clock edge
    end
endmodule

// gf180mcu_fd_sc_mcu9t5v0__udp_hn_iq_ff - D flip-flop (preset priority)
module gf180mcu_fd_sc_mcu9t5v0__udp_hn_iq_ff(Q, C, P, CK, D, N);
output reg Q;
input C, P, CK, D, N;
    always @(posedge CK or posedge C or posedge P) begin
        if (P)       Q <= 1'b1;  // Preset priority
        else if (C)  Q <= 1'b0;  // Clear
        else         Q <= D;     // Clock edge
    end
endmodule

// gf180mcu_fd_sc_mcu9t5v0__udp_n_iq_latch - Latch (clear priority)
module gf180mcu_fd_sc_mcu9t5v0__udp_n_iq_latch(Q, C, P, CK, D, N);
output reg Q;
input C, P, CK, D, N;
    always_latch begin
        if (C)       Q = 1'b0;   // Clear priority
        else if (P)  Q = 1'b1;   // Preset
        else if (CK) Q = D;      // Transparent when enabled
    end
endmodule

// gf180mcu_fd_sc_mcu9t5v0__udp_hn_iq_latch - Latch (preset priority)
module gf180mcu_fd_sc_mcu9t5v0__udp_hn_iq_latch(Q, C, P, CK, D, N);
output reg Q;
input C, P, CK, D, N;
    always_latch begin
        if (P)       Q = 1'b1;   // Preset priority
        else if (C)  Q = 1'b0;   // Clear
        else if (CK) Q = D;      // Transparent when enabled
    end
endmodule
