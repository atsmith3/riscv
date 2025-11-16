# Branch Evaluator Module Tests

## Overview

This test suite validates the branch evaluation unit that determines whether conditional branches should be taken based on register comparison results. The module implements all six RISC-V branch comparison operations and detects invalid opcodes.

## Module Under Test

**File**: `rtl/control/branch_eval.sv`

**Interface**:
- `input  logic [31:0] rs1` - First register value
- `input  logic [31:0] rs2` - Second register value
- `input  logic [2:0]  func` - Branch function (funct3 field)
- `output logic         branch` - Branch taken signal
- `output logic         exception` - Invalid operation exception

**Characteristics**:
- Purely combinational logic
- No clock or reset required
- Implements signed and unsigned comparisons

## Test Strategy

The test suite validates:
1. Correct comparison behavior for all six branch types
2. Signed vs unsigned comparison semantics
3. Edge cases with maximum, minimum, and equal values
4. Exception generation for reserved opcodes
5. Random comparison validation using reference model

## Test Cases

### branch_eval_beq

Tests Branch if Equal (func=000):
- Equal values produce branch=1
- Different values produce branch=0
- Zero comparison: 0 == 0 = true
- Maximum value: 0xFFFFFFFF == 0xFFFFFFFF = true
- No exceptions generated

### branch_eval_bne

Tests Branch if Not Equal (func=001):
- Different values produce branch=1
- Equal values produce branch=0
- Zero vs non-zero comparison
- Verifies logical negation of BEQ

### branch_eval_blt_signed

Tests Branch if Less Than signed (func=100):
- Positive comparisons: 10 < 20 = true
- Equal values: 15 == 15 = false
- Sign-extended comparisons:
  - -1 < 0 (0xFFFFFFFF < 0x00000000 signed) = true
  - 0 < -1 = false
  - -100 < -50 = true
- Boundary: min_signed < max_signed (0x80000000 < 0x7FFFFFFF) = true

### branch_eval_bge_signed

Tests Branch if Greater or Equal signed (func=101):
- Greater: 20 >= 10 = true
- Equal: 15 >= 15 = true
- Less: 10 >= 20 = false
- Sign-extended comparisons:
  - 0 >= -1 (0x00000000 >= 0xFFFFFFFF signed) = true
  - -1 >= 0 = false

### branch_eval_bltu_unsigned

Tests Branch if Less Than Unsigned (func=110):
- Standard unsigned: 10 < 20 = true
- Equal values: 15 == 15 = false
- Unsigned semantics validation:
  - 0 < 0xFFFFFFFF (unsigned) = true
  - 0xFFFFFFFF < 0 (unsigned) = false
- Demonstrates difference from signed comparison

### branch_eval_bgeu_unsigned

Tests Branch if Greater or Equal Unsigned (func=111):
- Greater: 20 >= 10 = true
- Equal: 15 >= 15 = true
- Less: 10 >= 20 = false
- Unsigned semantics:
  - 0xFFFFFFFF >= 0 (unsigned) = true
  - 0 >= 0xFFFFFFFF = false

### branch_eval_reserved_opcodes

Tests exception handling for reserved opcodes:
- func=010 (RESERVED_2): exception=1, branch=0
- func=011 (RESERVED_3): exception=1, branch=0
- Ensures illegal branch types are flagged

### branch_eval_edge_cases

Tests boundary conditions:
- All zeros (0x00000000)
- All ones (0xFFFFFFFF)
- Maximum positive signed (0x7FFFFFFF)
- Minimum negative signed (0x80000000)
- Validates signed vs unsigned interpretation differences

### branch_eval_random_operations

Executes 1000 randomized comparisons:
- Random 32-bit values for rs1 and rs2
- All function codes (0-7) including reserved
- Validates against C++ reference model
- Ensures correct behavior across full input space

## Reference Model

The `ref_branch_eval()` function implements the exact branch evaluation logic in C++:
- Returns (branch_taken, exception) tuple
- Implements signed comparisons using `static_cast<int32_t>`
- Implements unsigned comparisons using native unsigned types
- Detects reserved opcodes and sets exception flag

## Branch Function Encoding

Based on `datatypes.sv branch_t`:

| Function | Code | Description |
|----------|------|-------------|
| BEQ      | 000  | Branch if Equal |
| BNE      | 001  | Branch if Not Equal |
| RESERVED | 010  | Reserved (exception) |
| RESERVED | 011  | Reserved (exception) |
| BLT      | 100  | Branch if Less Than (signed) |
| BGE      | 101  | Branch if Greater or Equal (signed) |
| BLTU     | 110  | Branch if Less Than Unsigned |
| BGEU     | 111  | Branch if Greater or Equal Unsigned |

## Key Verification Points

1. **Signed Comparison Behavior**: Validates that signed comparisons treat 0x80000000 as most negative and 0x7FFFFFFF as most positive
2. **Unsigned Comparison Behavior**: Validates that unsigned comparisons treat 0xFFFFFFFF as largest value
3. **Exception Generation**: Ensures reserved opcodes cannot trigger branch
4. **Combinational Logic**: No setup/hold timing, results immediate after eval()

## Running the Tests

```bash
# Run all branch evaluator tests
./module_tests --run_test=BranchEval_ModuleTests

# Run specific test case
./module_tests --run_test=BranchEval_ModuleTests/branch_eval_blt_signed

# Run with verbose output
./module_tests --run_test=BranchEval_ModuleTests --log_level=all
```

## Coverage

The test suite provides:
- 100% coverage of valid branch operations (6 types)
- 100% coverage of reserved opcodes (2 types)
- Boundary value testing for signed/unsigned edge cases
- Statistical coverage via 1000 random test vectors
