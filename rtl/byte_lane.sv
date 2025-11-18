/*
 * Byte Lane Logic for Sub-Word Memory Operations
 *
 * This module handles byte and halfword load/store operations by:
 * - LOAD: Extracting and extending bytes/halfwords from 32-bit words
 * - STORE: Replicating byte/halfword data to correct byte lanes
 * - Generating byte enable signals for memory interface
 *
 * Educational RISC-V Core
 */

`include "datatypes.sv"

module byte_lane #(parameter WIDTH=32) (
  // Load path: mem_data_in -> load_data_out (with extraction and extension)
  input logic [WIDTH-1:0] mem_data_in,
  input mem_size_t load_size,
  input logic load_unsigned,
  input logic [1:0] addr_low,          // Address[1:0] for byte lane selection
  output logic [WIDTH-1:0] load_data_out,

  // Store path: store_data_in -> mem_data_out (with replication)
  input logic [WIDTH-1:0] store_data_in,
  input mem_size_t store_size,
  output logic [WIDTH-1:0] mem_data_out,

  // Byte enable generation
  output logic [3:0] byte_enable
);

// Load path: Extract and extend
always_comb begin
  case (load_size)
    MEM_SIZE_BYTE: begin
      // Extract byte based on address[1:0] and extend
      case (addr_low)
        2'b00: begin
          if (load_unsigned)
            load_data_out = {24'b0, mem_data_in[7:0]};
          else
            load_data_out = {{24{mem_data_in[7]}}, mem_data_in[7:0]};
        end
        2'b01: begin
          if (load_unsigned)
            load_data_out = {24'b0, mem_data_in[15:8]};
          else
            load_data_out = {{24{mem_data_in[15]}}, mem_data_in[15:8]};
        end
        2'b10: begin
          if (load_unsigned)
            load_data_out = {24'b0, mem_data_in[23:16]};
          else
            load_data_out = {{24{mem_data_in[23]}}, mem_data_in[23:16]};
        end
        2'b11: begin
          if (load_unsigned)
            load_data_out = {24'b0, mem_data_in[31:24]};
          else
            load_data_out = {{24{mem_data_in[31]}}, mem_data_in[31:24]};
        end
        default: begin
          if (load_unsigned)
            load_data_out = {24'b0, mem_data_in[7:0]};
          else
            load_data_out = {{24{mem_data_in[7]}}, mem_data_in[7:0]};
        end
      endcase
    end

    MEM_SIZE_HALF: begin
      // Extract halfword based on address[1] and extend
      case (addr_low[1])
        1'b0: begin
          if (load_unsigned)
            load_data_out = {16'b0, mem_data_in[15:0]};
          else
            load_data_out = {{16{mem_data_in[15]}}, mem_data_in[15:0]};
        end
        1'b1: begin
          if (load_unsigned)
            load_data_out = {16'b0, mem_data_in[31:16]};
          else
            load_data_out = {{16{mem_data_in[31]}}, mem_data_in[31:16]};
        end
        default: begin
          if (load_unsigned)
            load_data_out = {16'b0, mem_data_in[15:0]};
          else
            load_data_out = {{16{mem_data_in[15]}}, mem_data_in[15:0]};
        end
      endcase
    end

    MEM_SIZE_WORD: begin
      // Full word, no extension needed
      load_data_out = mem_data_in;
    end

    default: begin
      load_data_out = mem_data_in;
    end
  endcase
end

// Store path: Replicate data to correct byte lanes
always_comb begin
  case (store_size)
    MEM_SIZE_BYTE: begin
      // Replicate byte to all lanes (memory will use byte_enable to select)
      mem_data_out = {4{store_data_in[7:0]}};
    end

    MEM_SIZE_HALF: begin
      // Replicate halfword to both halfword positions
      mem_data_out = {2{store_data_in[15:0]}};
    end

    MEM_SIZE_WORD: begin
      // Pass through full word
      mem_data_out = store_data_in;
    end

    default: begin
      mem_data_out = store_data_in;
    end
  endcase
end

// Byte enable generation
always_comb begin
  case (store_size)
    MEM_SIZE_BYTE: begin
      // Only one byte enable active based on address[1:0]
      case (addr_low)
        2'b00: byte_enable = 4'b0001;
        2'b01: byte_enable = 4'b0010;
        2'b10: byte_enable = 4'b0100;
        2'b11: byte_enable = 4'b1000;
        default: byte_enable = 4'b0001;  // Should not happen
      endcase
    end

    MEM_SIZE_HALF: begin
      // Two byte enables active based on address[1]
      case (addr_low[1])
        1'b0: byte_enable = 4'b0011;  // Lower halfword
        1'b1: byte_enable = 4'b1100;  // Upper halfword
        default: byte_enable = 4'b0011;  // Should not happen
      endcase
    end

    MEM_SIZE_WORD: begin
      // All byte enables active
      byte_enable = 4'b1111;
    end

    default: begin
      byte_enable = 4'b1111;
    end
  endcase
end

endmodule : byte_lane
