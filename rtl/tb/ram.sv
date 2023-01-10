/*
 * Parameterized Single Port Memory with Customizable Response Delay
 *
 * 2022-11-12
 */

`timescale 1ns/1ns

module memory_model #(
  parameter DATA_WIDTH=8,
  parameter ADDR_WIDTH=32,
  parameter DELAY=0,
  parameter MEM_INIT_FILE="/home/andrew/proj/riscv/rtl/tb/test_roms/test.mem"
) 
( input clk,
  input read,
  input write,
  input logic rst_n,
  input logic [DATA_WIDTH-1:0] data_in,
  output logic [DATA_WIDTH-1:0] data_out,
  input logic [ADDR_WIDTH-1:0] addr,
  output logic resp);

  reg [7:0] mem [2**ADDR_WIDTH-1:0];
  reg [31:0] count;
  reg [DATA_WIDTH-1:0] out_buffer;
  reg old_read;
  reg old_write;

  initial begin
    $readmemh(MEM_INIT_FILE,mem,0,2**ADDR_WIDTH-1);
  end

  enum {
    IDLE = 0,
    WAIT_READ,
    WAIT_WRITE,
    DONE
  } state, next_state;

  always_ff @ ( posedge clk ) begin
    if (!rst_n) begin
      state <= IDLE;
      old_read <= 0;
      old_write <= 0;
    end
    else begin
      state <= next_state;
      old_read <= read;
      old_write <= write;
      count <= 0;
      if (state == WAIT_READ || state == WAIT_WRITE) begin
        count <= count + 1;
      end
      out_buffer <= out_buffer;
      if (state == DONE) begin
        if (read) begin 
          out_buffer <= {mem[addr+3],mem[addr+2],mem[addr+1],mem[addr]};
        end
        if (write) begin
          //out_buffer <= {mem[addr+3],mem[addr+2],mem[addr+1],mem[addr]};
        end
      end
    end
  end

  // Output Logic
  always_comb begin
    resp = 0;
    case (state)
      DONE : begin
        resp = 1'b1;
      end
      default : begin

      end
    endcase
  end

  // Next State Logic
  always_comb begin
    next_state = IDLE;
    case (state)
      IDLE : begin
        if (~old_read & read) begin
          next_state = WAIT_READ;
        end
        if (~old_write & write) begin
          next_state = WAIT_WRITE;
        end
      end
      WAIT_READ : begin
        next_state = WAIT_READ;
        if (count >= DELAY-1) begin
          next_state = DONE;
        end
      end
      WAIT_WRITE : begin
        next_state = WAIT_WRITE;
        if (count >= DELAY-1) begin
          next_state = DONE;
        end
      end
      DONE: begin
        next_state = IDLE;
      end
      default: begin

      end
    endcase
  end

  assign data_out = out_buffer;

endmodule


`ifdef TESTBENCH
module tb ();
  localparam DATA_WIDTH=8;
  localparam ADDR_WIDTH=4;

  reg clk;
  reg read;
  reg write;
  reg resp;
  reg [DATA_WIDTH-1:0] data_in;
  reg [DATA_WIDTH-1:0] data_out;
  reg [ADDR_WIDTH-1:0] addr;

  initial begin
    $dumpfile("test.vcd");
    $dumpvars(0,tb);
  end

  memory_model #(.ADDR_WIDTH(ADDR_WIDTH)) u_single_port_ram (
    .clk(clk),
    .read(read),
    .write(write),
    .resp(resp),
    .data_in(data_in),
    .data_out(data_out),
    .addr(addr));

  always #10 clk = ~clk;

  initial begin
    clk <= 0;
    read <= 0;
    write <= 0;
    data_in <= 0;
    addr <= 0;
    
    for (integer i = 0; i < 2**ADDR_WIDTH; i= i+1) begin
      repeat (1) @(posedge clk) addr <= i; read <= 1; write <= 0;
    end
    
    #100 $finish;
  end
endmodule
`endif
