# ALU Module Tests

## Overview

This test suite validates the Arithmetic Logic Unit (ALU) module of the RISC-V 32I core. The ALU performs all arithmetic, logical, shift, and comparison operations as specified in the RISC-V ISA.

## Module Under Test

**File**: `rtl/alu/alu.sv`

**Interface**:
- `input  logic [31:0] a` - First operand
- `input  logic [31:0] b` - Second operand
- `input  logic [3:0]  op` - Operation selector
- `output logic [31:0] y` - Result

## Test Strategy

The test suite employs three verification approaches:

1. **Directed Tests**: Known input/output pairs for each operation
2. **Boundary Tests**: Edge cases including zero, maximum values, and overflow conditions
3. **Random Tests**: 1000 randomized operations validated against a reference model

## Test Cases

### alu_add_operation

Tests addition operation (op=0):
- Basic addition: 10 + 20 = 30
- Zero operands: 0 + 0 = 0
- Overflow behavior: 0xFFFFFFFF + 1 = 0 (32-bit wraparound)

### alu_sub_operation

Tests subtraction operation (op=1):
- Basic subtraction: 50 - 20 = 30
- Underflow behavior: 10 - 20 = 0xFFFFFFF6 (two's complement)
- Zero result: 42 - 42 = 0

### alu_logical_operations

Tests bitwise logical operations:
- **AND** (op=4): 0xF0F0F0F0 & 0x0F0F0F0F = 0
- **OR** (op=5): 0xF0F0F0F0 | 0x0F0F0F0F = 0xFFFFFFFF
- **XOR** (op=6): 0xAAAAAAAA ^ 0x55555555 = 0xFFFFFFFF

### alu_shift_operations

Tests shift operations with shamt derived from lower 5 bits of operand b:
- **Shift Left Logical** (op=2): 1 << 4 = 16
- **Shift Right Logical** (op=7): 0x80000000 >> 1 = 0x40000000
- **Shift Right Arithmetic** (op=9): 0x80000000 >> 1 = 0xC0000000 (sign extension)
- Shift amount masking: Uses only b[4:0] per RISC-V specification

### alu_comparison_operations

Tests comparison operations:
- **Set Less Than (signed)** (op=3): Returns 1 if signed(a) < signed(b), else 0
  - Positive comparison: 10 < 20 = 1
  - Negative comparison: -1 < 0 = 1 (0xFFFFFFFF < 0x00000000 signed)
- **Set Less Than Unsigned** (op=8): Returns 1 if a < b (unsigned), else 0
  - Unsigned comparison: 10 < 20 = 1
  - Unsigned wraparound: 0xFFFFFFFF > 0x00000000 = 0

### alu_random_operations

Executes 1000 randomized test vectors:
- Random 32-bit operands a and b
- Random valid operation codes: {0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 13}
- Each result validated against C++ reference model
- Ensures comprehensive functional coverage across all operations

## Reference Model

The test suite includes a software reference model (`ref_alu()`) that implements the exact ALU behavior in C++. All test cases verify the RTL output matches the reference model output, ensuring bit-accurate correctness.

## Operation Encoding

Based on `datatypes.sv`:

| Operation | Code | Description |
|-----------|------|-------------|
| ADD       | 0    | Addition |
| SLL       | 1    | Shift Left Logical |
| SLT       | 2    | Set Less Than (signed) |
| SLTU      | 3    | Set Less Than Unsigned |
| XOR       | 4    | Bitwise XOR |
| SRL       | 5    | Shift Right Logical |
| OR        | 6    | Bitwise OR |
| AND       | 7    | Bitwise AND |
| SUB       | 8    | Subtraction |
| PASS_RS1  | 9    | Pass-through of operand A |
| PASS_RS2  | 10   | Pass-through of operand B |
| SRA       | 13   | Shift Right Arithmetic |

## Running the Tests

```bash
# Run all ALU tests
./module_tests --run_test=ALU_ModuleTests

# Run specific test case
./module_tests --run_test=ALU_ModuleTests/alu_add_operation

# Run with verbose output
./module_tests --run_test=ALU_ModuleTests --log_level=all
```

## Coverage

The test suite achieves comprehensive functional coverage:
- All 12 ALU operations tested
- Boundary conditions validated (zero, max values, overflow/underflow)
- Signed vs unsigned comparison behavior verified
- Shift amount masking validated
- 1000 random vectors provide statistical coverage
