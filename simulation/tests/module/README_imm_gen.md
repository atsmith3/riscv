# Immediate Generator Module Tests

## Overview

This test suite validates the 32-bit immediate generator that extracts and sign-extends immediate values from RISC-V instruction encodings. The module supports all five RISC-V instruction formats that contain immediate fields.

## Module Under Test

**File**: `rtl/control/imm_gen.sv`

**Module**: `imm_gen_32`

**Interface**:
- `input  logic [31:0] ir` - Instruction register (encoded instruction)
- `input  logic [2:0]  instr_type` - Instruction format type
- `output logic [31:0] imm` - Sign-extended immediate value

**Characteristics**:
- Purely combinational logic
- Implements bit field extraction and sign extension
- Produces word-aligned immediates for B-type and J-type (LSB=0)

## Test Strategy

The test suite validates:
1. Correct bit field extraction for each instruction format
2. Sign extension behavior for positive and negative immediates
3. Zero-forcing of lower bits for U-type, B-type, and J-type
4. Boundary conditions (maximum positive, maximum negative, zero)
5. Real RISC-V instruction encodings
6. Reference model validation across diverse bit patterns

## Test Cases

### imm_gen_i_type

Tests I-type immediate generation (bits [31:20]):
- **Format**: Sign-extend ir[31:20]
- **Range**: -2048 to +2047 (12-bit signed)
- Test vectors:
  - Positive: 100 = 0x000000064
  - Negative: -100 = 0xFFFFFFF9C
  - Zero: 0 = 0x00000000
  - Max positive: 2047 (0x7FF) = 0x000007FF
  - Max negative: -2048 (0x800) = 0xFFFFF800
  - All ones: -1 (0xFFF) = 0xFFFFFFFF
- Validates sign extension for bit 31

### imm_gen_s_type

Tests S-type immediate generation (bits [31:25,11:7]):
- **Format**: Sign-extend {ir[31:25], ir[11:7]}
- **Range**: -2048 to +2047 (12-bit signed)
- Test vectors:
  - Positive: 100 = 0x00000064
  - Negative: -100 = 0xFFFFFF9C
  - Max positive: 2047 (0x7FF)
  - Max negative: -2048 (0x800)
  - Alternating bits: 0x555 to verify correct field extraction
- Validates proper reassembly of split immediate fields

### imm_gen_b_type

Tests B-type immediate generation (bits [31,7,30:25,11:8,0]):
- **Format**: Sign-extend {ir[31], ir[7], ir[30:25], ir[11:8], 1'b0}
- **Range**: -4096 to +4094 (13-bit signed, multiples of 2)
- **LSB**: Always 0 (word alignment)
- Test vectors:
  - Positive offset: +8 = 0x00000008
  - Negative offset: -8 = 0xFFFFFFF8
  - Zero offset: 0 = 0x00000000
  - Max positive: 4094 (0xFFE)
  - Max negative: -4096 (0x1000)
- Validates LSB is always 0 for all values
- Confirms sign extension from bit 12

### imm_gen_u_type

Tests U-type immediate generation (bits [31:12]):
- **Format**: {ir[31:12], 12'b0}
- **Range**: Upper 20 bits, no sign extension
- **Lower 12 bits**: Always 0
- Test vectors:
  - 0x12345 << 12 = 0x12345000
  - 0x00000 << 12 = 0x00000000
  - 0xFFFFF << 12 = 0xFFFFF000
  - 0xABCDE << 12 = 0xABCDE000
- Validates lower 12 bits are always 0
- Verifies no sign extension occurs

### imm_gen_j_type

Tests J-type immediate generation (bits [31,19:12,20,30:21,0]):
- **Format**: Sign-extend {ir[31], ir[19:12], ir[20], ir[30:21], 1'b0}
- **Range**: -1048576 to +1048574 (21-bit signed, multiples of 2)
- **LSB**: Always 0 (word alignment)
- Test vectors:
  - Positive offset: +8 = 0x00000008
  - Negative offset: -100 = 0xFFFFFF9C
  - Zero offset: 0 = 0x00000000
  - Max positive: 0xFFFFE (bit 20 clear)
  - Max negative: -1048576 (bit 20 set)
- Validates LSB is always 0 for all values
- Confirms sign extension from bit 20

### imm_gen_r_type

Tests R-type instruction handling:
- **Expected**: imm = 0 (R-type has no immediate field)
- Validates that all input patterns produce zero output
- Ensures proper handling of non-immediate instruction types

### imm_gen_error_type

Tests error/invalid instruction type handling:
- **Expected**: imm = 0 for INSTR_ERR
- Validates graceful handling of invalid instruction types

### imm_gen_real_instructions

Tests with actual RISC-V instruction encodings:
- **ADDI x5, x0, 10**: I-type, imm=10
- **LUI x10, 0x12345**: U-type, imm=0x12345000
- **SW x5, 100(x2)**: S-type, imm=100
- **BEQ x1, x2, -8**: B-type, imm=-8
- **JAL x1, 2048**: J-type, imm=2048
- Validates immediate extraction from complete instruction encodings

### imm_gen_sign_extension

Tests sign extension correctness:
- **I-type**: 0xFFF = 0xFFFFFFFF (all upper bits set)
- **S-type**: 0xFFF = 0xFFFFFFFF
- **B-type**: 0x1FFE = 0xFFFFFFFE (sign-extended, LSB=0)
- **J-type**: 0x1FFFFE = 0xFFFFFFFE (sign-extended, LSB=0)
- Validates that sign bit propagates correctly

### imm_gen_reference_model

Tests against reference model with diverse patterns:
- Test patterns: 0x00000000, 0xFFFFFFFF, 0x12345678, 0xABCDEF01, 0x55555555, 0xAAAAAAAA, 0x7FFFFFFF, 0x80000000
- All instruction types: R, I, S, B, U, J, ERR
- Validates bit-accurate matching between RTL and reference model

## Reference Model

The `ref_imm_gen()` function implements the RISC-V immediate generation logic in C++:
- Extracts appropriate bit fields based on instruction type
- Performs sign extension using two's complement arithmetic
- Enforces LSB=0 for B-type and J-type immediates
- Returns 32-bit sign-extended immediate value

## Instruction Type Encoding

Based on `datatypes.sv instr_format_t`:

| Type    | Code | Immediate Format |
|---------|------|------------------|
| INSTR_R | 0    | No immediate (returns 0) |
| INSTR_I | 1    | [31:20] sign-extended |
| INSTR_S | 2    | [31:25,11:7] sign-extended |
| INSTR_B | 3    | [31,7,30:25,11:8,0] sign-extended |
| INSTR_U | 4    | [31:12,0...0] no sign extension |
| INSTR_J | 5    | [31,19:12,20,30:21,0] sign-extended |
| INSTR_ERR | 6 | Invalid (returns 0) |

## Immediate Bit Fields

### I-Type (12-bit signed)
```
[31:20] = immediate
Sign-extended to 32 bits
```

### S-Type (12-bit signed)
```
[31:25] = imm[11:5]
[11:7]  = imm[4:0]
Sign-extended to 32 bits
```

### B-Type (13-bit signed, even offsets)
```
[31]     = imm[12]
[7]      = imm[11]
[30:25]  = imm[10:5]
[11:8]   = imm[4:1]
imm[0]   = 0 (implicit)
Sign-extended to 32 bits
```

### U-Type (20-bit unsigned)
```
[31:12] = imm[31:12]
imm[11:0] = 0 (implicit)
No sign extension
```

### J-Type (21-bit signed, even offsets)
```
[31]     = imm[20]
[19:12]  = imm[19:12]
[20]     = imm[11]
[30:21]  = imm[10:1]
imm[0]   = 0 (implicit)
Sign-extended to 32 bits
```

## Running the Tests

```bash
# Run all immediate generator tests
./module_tests --run_test=ImmGen_ModuleTests

# Run specific test case
./module_tests --run_test=ImmGen_ModuleTests/imm_gen_b_type

# Run with verbose output
./module_tests --run_test=ImmGen_ModuleTests --log_level=all
```

## Coverage

The test suite provides:
- 100% coverage of all instruction format types
- Sign extension validation for positive and negative values
- Boundary value testing (0, max positive, max negative)
- Real instruction encoding validation
- Reference model validation across 8 diverse bit patterns per instruction type
