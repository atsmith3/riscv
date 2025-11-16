# Instruction Decoder Module Tests

## Overview

This test suite validates the RISC-V instruction decoder that extracts all fields from 32-bit instruction encodings and determines the instruction format type. The decoder is a critical component of the control path that interprets fetched instructions.

## Module Under Test

**File**: `rtl/control/decoder.sv`

**Module**: `ir_decoder`

**Interface**:
- `input  logic [31:0] ir` - Instruction register (32-bit instruction)
- `output logic [2:0]  instr_type` - Instruction format (R/I/S/B/U/J/ERR)
- `output logic [6:0]  opcode` - Opcode field [6:0]
- `output logic [4:0]  rs1` - Source register 1 address [19:15]
- `output logic [4:0]  rs2` - Source register 2 address [24:20]
- `output logic [4:0]  rd` - Destination register address [11:7]
- `output logic [6:0]  funct7` - Function field 7 [31:25]
- `output logic [2:0]  funct3` - Function field 3 [14:12]
- `output logic [3:0]  fm` - FENCE ordering bits [31:28]
- `output logic [3:0]  pred` - FENCE predecessor [27:24]
- `output logic [3:0]  succ` - FENCE successor [23:20]
- `output logic        arithmetic` - Bit 30 (SUB/SRA vs ADD/SRL)
- `output logic        ebreak` - EBREAK instruction detection
- `output logic [31:0] immediate` - Sign-extended immediate (from imm_gen_32)

**Characteristics**:
- Purely combinational logic
- Instantiates imm_gen_32 for immediate generation
- Determines instruction format based on opcode

## Test Strategy

The test suite validates:
1. Correct instruction format identification for all opcodes
2. Bit field extraction for all instruction formats
3. Immediate value generation (via imm_gen_32 integration)
4. Special field extraction (FENCE, EBREAK)
5. Arithmetic bit detection for ALU operation disambiguation
6. Invalid opcode detection
7. Real RISC-V instruction decoding

## Test Cases

### decoder_r_type

Tests R-type instruction decoding (register-register operations):
- **Format**: opcode[6:0] | rd[4:0] | funct3[2:0] | rs1[4:0] | rs2[4:0] | funct7[6:0]
- **ADD x5, x6, x7** (funct7=0000000):
  - Validates all field extraction
  - Verifies instr_type=INSTR_R
  - Confirms arithmetic=0 (bit 30 clear)
  - Ensures immediate=0 (R-type has no immediate)
- **SUB x1, x2, x3** (funct7=0100000):
  - Validates arithmetic=1 (bit 30 set, distinguishes from ADD)
- **SRA x10, x11, x12**:
  - Validates funct3=101 extraction
  - Confirms arithmetic=1 (bit 30 set, distinguishes from SRL)

### decoder_i_type

Tests I-type instruction decoding (immediate operations, loads):
- **Format**: imm[11:0] | rs1[4:0] | funct3[2:0] | rd[4:0] | opcode[6:0]
- **ADDI x5, x6, 100** (opcode=0010011):
  - Validates immediate extraction and sign extension
  - Verifies instr_type=INSTR_I
  - Confirms all register fields
- **LW x1, 50(x2)** (opcode=0000011):
  - Validates load instruction decoding
  - Confirms funct3=010 (word width)
- **JALR x1, x2, 8** (opcode=1100111):
  - Validates jump-and-link-register format
- **Negative immediate** test (0xFFF):
  - Confirms sign extension: imm=0xFFFFFFFF

### decoder_s_type

Tests S-type instruction decoding (store operations):
- **Format**: imm[11:5] | rs2[4:0] | rs1[4:0] | funct3[2:0] | imm[4:0] | opcode[6:0]
- **SW x5, 100(x6)** (opcode=0100011):
  - Validates split immediate field reassembly
  - Verifies rs1 (base register) and rs2 (source register) extraction
  - Confirms instr_type=INSTR_S
- **SH x1, 50(x2)** (funct3=001):
  - Validates halfword store encoding
- **SB x3, -4(x4)**:
  - Validates negative offset with sign extension

### decoder_b_type

Tests B-type instruction decoding (conditional branches):
- **Format**: imm[12,10:5] | rs2[4:0] | rs1[4:0] | funct3[2:0] | imm[4:1,11] | opcode[6:0]
- **BEQ x1, x2, 8** (funct3=000):
  - Validates branch immediate extraction
  - Confirms LSB of immediate is always 0
  - Verifies instr_type=INSTR_B
- **BLT x5, x6, -16** (funct3=100):
  - Validates negative branch offset
  - Confirms sign extension behavior

### decoder_u_type

Tests U-type instruction decoding (upper immediate):
- **Format**: imm[31:12] | rd[4:0] | opcode[6:0]
- **LUI x5, 0x12345** (opcode=0110111):
  - Validates upper immediate extraction: imm=0x12345000
  - Confirms lower 12 bits are zero
  - Verifies instr_type=INSTR_U
- **AUIPC x10, 0xABCDE** (opcode=0010111):
  - Validates add-upper-immediate-to-PC format

### decoder_j_type

Tests J-type instruction decoding (unconditional jumps):
- **Format**: imm[20,10:1,11,19:12] | rd[4:0] | opcode[6:0]
- **JAL x1, 2048**:
  - Validates jump immediate extraction
  - Confirms LSB of immediate is always 0
  - Verifies instr_type=INSTR_J
- **JAL x0, -100** (rd=x0 for simple jump):
  - Validates negative jump offset with sign extension

### decoder_fence

Tests FENCE instruction field extraction:
- **Format**: fm[3:0] | pred[3:0] | succ[3:0] | rs1[4:0] | funct3[2:0] | rd[4:0] | opcode[6:0]
- **FENCE** instruction:
  - Validates fm (fence mode) field extraction
  - Confirms pred (predecessor) field extraction
  - Verifies succ (successor) field extraction
  - Ensures instr_type=INSTR_I (FENCE uses I-type format)

### decoder_ebreak

Tests EBREAK instruction detection:
- **EBREAK** encoding (opcode=1110011, funct3=000, imm=000000000001):
  - Validates ebreak signal asserts
  - Confirms instr_type=INSTR_I
- **ECALL** encoding (imm=000000000000):
  - Validates ebreak signal does NOT assert
  - Ensures proper distinction between ECALL and EBREAK

### decoder_all_opcodes

Tests all valid RISC-V 32I opcodes:
- **LUI** (0110111): Expects INSTR_U
- **AUIPC** (0010111): Expects INSTR_U
- **JAL** (1101111): Expects INSTR_J
- **JALR** (1100111): Expects INSTR_I
- **BRANCH** (1100011): Expects INSTR_B
- **LD** (0000011): Expects INSTR_I
- **ST** (0100011): Expects INSTR_S
- **ALUI** (0010011): Expects INSTR_I
- **ALU** (0110011): Expects INSTR_R
- **FENCE** (0001111): Expects INSTR_I
- **ECSR** (1110011): Expects INSTR_I
- Validates instruction type determination logic

### decoder_invalid_opcodes

Tests invalid/reserved opcode handling:
- **Invalid opcodes**: 0000000, 0000001, 0001000, 1111111
- **Expected**: instr_type=INSTR_ERR for all invalid opcodes
- Ensures decoder does not misclassify invalid instructions

### decoder_field_extraction

Tests comprehensive register field extraction:
- **rd extraction**: Tests all 32 register addresses (x0-x31)
- **rs1 extraction**: Tests all 32 register addresses
- **rs2 extraction**: Tests sampled register addresses
- **funct3 extraction**: Tests all 8 possible values (0-7)
- **funct7 extraction**: Tests sampled values (0-127)
- Validates bit field masking and shifting

### decoder_arithmetic_bit

Tests arithmetic bit (bit 30) for ALU operation disambiguation:
- **ADD** (funct7=0000000): arithmetic=0
- **SUB** (funct7=0100000): arithmetic=1
- **SRL** (funct3=101, funct7=0000000): arithmetic=0
- **SRA** (funct3=101, funct7=0100000): arithmetic=1
- Enables ALU to distinguish ADD/SUB and SRL/SRA operations

### decoder_real_instructions

Tests decoding of actual RISC-V assembly instructions:
- **addi x5, x0, 42**: I-type (pseudo-instruction li)
- **add x1, x2, x3**: R-type
- **lw x4, 100(x5)**: I-type load
- **sw x6, 200(x7)**: S-type store
- **beq x8, x9, 16**: B-type branch
- **lui x10, 0x12345**: U-type
- **jal x1, 1024**: J-type
- Validates end-to-end instruction decoding

## Opcode Encoding

Based on `datatypes.sv opcode_t`:

| Mnemonic | Opcode   | Instr Type | Description |
|----------|----------|------------|-------------|
| LUI      | 0110111  | U          | Load Upper Immediate |
| AUIPC    | 0010111  | U          | Add Upper Immediate to PC |
| JAL      | 1101111  | J          | Jump and Link |
| JALR     | 1100111  | I          | Jump and Link Register |
| BRANCH   | 1100011  | B          | Conditional Branches |
| LD       | 0000011  | I          | Load Operations |
| ST       | 0100011  | S          | Store Operations |
| ALUI     | 0010011  | I          | ALU Immediate Operations |
| ALU      | 0110011  | R          | ALU Register Operations |
| FENCE    | 0001111  | I          | Memory Ordering |
| ECSR     | 1110011  | I          | Environment/CSR |

## Instruction Format Types

Based on `datatypes.sv instr_format_t`:

| Type      | Code | Used By |
|-----------|------|---------|
| INSTR_R   | 0    | ALU register-register |
| INSTR_I   | 1    | ALU immediate, loads, JALR, FENCE, ECSR |
| INSTR_S   | 2    | Store operations |
| INSTR_B   | 3    | Conditional branches |
| INSTR_U   | 4    | LUI, AUIPC |
| INSTR_J   | 5    | JAL |
| INSTR_ERR | 6    | Invalid/reserved opcodes |

## Integration with Immediate Generator

The decoder instantiates `imm_gen_32` to generate sign-extended immediates:
- Passes instruction register (ir) and instruction type (instr_type)
- Receives 32-bit sign-extended immediate
- Eliminates need for separate immediate extraction in pipeline stages

## Running the Tests

```bash
# Run all decoder tests
./module_tests --run_test=Decoder_ModuleTests

# Run specific test case
./module_tests --run_test=Decoder_ModuleTests/decoder_r_type

# Run with verbose output
./module_tests --run_test=Decoder_ModuleTests --log_level=all
```

## Coverage

The test suite provides:
- 100% coverage of all 11 valid RISC-V 32I opcodes
- 100% coverage of all 6 instruction format types
- 100% coverage of register field extraction (all 32 registers)
- 100% coverage of funct3 values (0-7)
- Sampled coverage of funct7 values
- Invalid opcode detection validation
- Special field extraction (FENCE, EBREAK)
- Real instruction encoding validation
