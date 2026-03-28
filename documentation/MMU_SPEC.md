# MMU Specification for Potato RV32I

## Overview

This document specifies the Memory Management Unit (MMU) implementation for the Potato RV32I processor. The MMU provides full virtual memory support with TLB, page tables, and Physical Memory Protection (PMP) as defined in the RISC-V Privileged Specification v1.12.

**Scope**: This specification is strictly for RV32I with 32-bit virtual and physical address spaces. RV64/RV128 support is explicitly out of scope.

## Design Decisions and Rationale

### Physical Address Space
- **Size**: 4GB (32-bit physical address space)
- **Rationale**: Matches the 32-bit virtual address space, allowing full 1:1 mapping capability
- **PFN Size**: 20 bits (supports 4GB physical memory)

### TLB Design
- **Entries**: 16 entries (fixed)
- **Associativity**: Direct-mapped (1-way)
- **Rationale**:
  - 16 entries cover 64MB of virtual address space (for 4KB pages)
  - Direct-mapped is simplest and sufficient for RV32I
  - Fixed size simplifies implementation
- **Refill Policy**: On TLB miss, page walker walks page table and writes to TLB
- **LRU**: Not implemented (direct-mapped)
- **Context Switch**: TLB entries are invalidated on privilege mode change

### Page Table Storage
- **Implementation**: Register-based storage for simplicity
- **Size**: 1M entries (2^20) for 4GB virtual address space with 4KB pages
- **Rationale**:
  - 1M entries × 32 bits = 32MB of page table storage
  - For RV32I, register-based is acceptable
  - Single-level page tables are sufficient for 32-bit address space
- **Mutex**: A single mutex signal ensures exclusive access to page table during concurrent operations

### Page Walker
- **Latency**: Synchronous, multi-cycle operation
- **Rationale**:
  - Multi-cycle allows time for page table access
  - Can be pipelined for better performance
- **Concurrent Access**: Page walker can read/write PTEs during walk, protected by mutex
- **Page Fault Handling**: If PTE invalid, trigger page fault and allow software to create mapping

### Address Translation
- **Latency**: Single cycle for TLB hit, multi-cycle for TLB miss
- **Rationale**:
  - TLB hit is single cycle (array lookup)
  - TLB miss requires page walk (multiple cycles)
- **Concurrent Access**: Only one translation at a time (serialized by mutex)

### Trap Handling
- **sepc Saving**: Save instruction PC at fault time
- **Multi-cycle Instructions**: For multi-cycle instructions, save PC at start of instruction
- **Rationale**:
  - Need to resume instruction after fault handling
  - Multi-cycle instructions need special handling to avoid partial state

### PMP Design
- **Regions**: 16 PMP regions (PMPADDR0-15, PMPCFG0-15)
- **Rationale**:
  - Full RISC-V spec compliance (16 regions)
  - Supports complex memory protection scenarios
- **Check Timing**: PMP check in parallel with TLB for single-cycle violation detection
- **PMP Modes**: Support all modes (tor, napot, off)

### CSR Implementation
- **S-mode CSRs**: Complete set (SSTATUS, SIP, STVEC, SIE, SSCRATCH, SBADADDR, SEPC, SCAUSE, SATP, MIDELEG, MEDELEG)
- **M-mode CSRs**: Complete set (MSTATUS, MIE, MTVEC, MEPC, MCAUSE, MTVAL, MSCRATCH, MIP, MIDELEG, MEDELEG)
- **PMP CSRs**: 16 address + 16 config registers (32 total)
- **Rationale**:
  - Implement complete CSR set for proper MMU operation
  - Supports exception delegation and interrupt handling
  - CSR read/write is single-cycle for simplicity

### Virtual Address Format
- **Format**: sv32 (32-bit virtual address)
- **VPN**: 20 bits (for 4KB pages)
- **ASID**: 4 bits (16 address spaces)
- **Offset**: 12 bits (4KB page size)
- **Rationale**:
  - sv32 matches physical address space
  - 4-bit ASID provides 16 address spaces (good for multitasking)
  - 4KB pages are standard for most workloads

### Satp Register
- **Modes**: Mode 0 (no translation), Mode 1 (sv32)
- **Default**: 0x00000000 on reset (no translation)
- **Rationale**:
  - Start simple with sv32
  - Default 0 ensures safe operation without MMU

### FSM Integration
- **MMU States**: TLB_HIT, TLB_MISS, PAGE_FAULT_0/1/2, PMP_VIOLATION
- **PAGE_FAULT Latency**: 3 cycles (save context, write registers, jump handler)
- **PMP Check**: Single cycle (parallel with TLB)
- **Rationale**:
  - Multi-cycle page fault allows proper context saving
  - Single-cycle PMP check keeps critical path short
  - States integrate with existing FSM structure

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────────┐
│                        MMU MODULE                                │
├─────────────────────────────────────────────────────────────────┤
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────────────┐   │
│  │   TLB (16)   │  │ Page Walker  │  │  Page Table Store    │   │
│  └──────┬───────┘  └──────┬───────┘  └──────────┬───────────┘   │
│         │                 │                      │               │
│         └────────┬────────┴──────────────────────┘               │
│                  ▼                                               │
│         ┌──────────────┐                                        │
│         │ Addr Trans   │◄─── Virtual Address (32-bit)           │
│         └──────┬───────┘                                        │
│                │                                                 │
│                ▼                                                 │
│         ┌──────────────┐                                        │
│         │  PF Check    │◄─── Permissions (R/W/X)                │
│         └──────┬───────┘                                        │
│                │                                                 │
│                ▼                                                 │
│         ┌──────────────┐                                        │
│         │ Physical Addr│───► To Memory Interface                │
│         └──────────────┘                                        │
└─────────────────────────────────────────────────────────────────┘
```

## New Modules

### 1. `rtl/mmu/tlb.sv` - Translation Lookaside Buffer

**Purpose**: Hardware cache for virtual-to-physical address translations.

**Parameters**:
- `NUM_ENTRIES`: 16 (fixed)

**Interface**:
```systemverilog
module tlb #(
    parameter NUM_ENTRIES = 16
)(
    input  logic clk,
    input  logic rst_n,

    // Address translation interface (time-multiplexed for simplicity)
    input  logic [31:0] vaddr,      // Virtual address (always present)
    input  logic [3:0] tlb_idx,     // Which 4 entries to compare (0-3)
    input  logic [3:0] entry_valid, // Valid entries in this group
    output logic [31:0] paddr,      // Physical address
    output logic tlb_hit,           // TLB hit signal (1 cycle per group)
    output logic page_fault,        // Page fault detected
    output logic [2:0] perm,        // Permissions (R/W/X)

    // TLB maintenance
    input  logic tlb_we,            // TLB write enable
    input  logic [19:0] vpn,        // Virtual page number to write
    input  logic [19:0] pfn,        // Physical frame number to write
    input  logic valid,             // Valid bit
    input  logic dirty,             // Dirty bit
    input  logic [2:0] perm_write,  // Permissions to write
    input  logic [3:0] asid,        // Address space ID
    input  logic invalidate,        // Invalidate TLB entry
    input  logic flush_all,         // Flush all TLB entries

    // Pipeline control
    output logic stall,             // Stall signal for pipeline (4 cycles total)
    output logic [31:0] bad_vaddr,  // Bad virtual address on fault
    output logic [31:0] bad_paddr,  // Bad physical address on fault
    output logic [2:0] fault_type,  // Fault type (0=none, 1=access, 2=fetch)

    // Mutex for exclusive access
    input  logic pte_mutex,         // Page table mutex (high = exclusive access)
    output logic pte_mutex_req      // Mutex request
);
```

**Design Notes**:
- **Time-Multiplexed Tag Comparison**: Compares 4 entries per cycle (4 cycles for all 16)
- **Simple Interface**: Clear control signals, no hidden complexity
- **Educational Value**: Easy to trace data flow and debug
- **Trade-off**: 4× latency for 75% reduction in routing complexity

**TLB Entry Format** (32 bits):
```
[19:0] PFN    - Physical Frame Number (20 bits for 4KB pages)
[20]  Dirty   - Dirty bit
[21]  Reserved
[22]  Access  - Access bit
[23]  W       - Write bit
[24]  R       - Read bit
[25]  Valid   - Valid bit
[26:31] Reserved
```

### 2. `rtl/mmu/page_table.sv` - Page Table Storage

**Purpose**: Store page table entries (PTEs) for virtual memory management.

**Interface**:
```systemverilog
module page_table #(
    parameter PTE_WIDTH = 32,
    parameter NUM_ENTRIES = 1048576  // 1M entries for 4GB space
)(
    input  logic clk,
    input  logic rst_n,

    // PTE read
    input  logic [19:0] vpn,       // Virtual page number to read
    output logic [31:0] pte,       // Page table entry

    // PTE write
    input  logic pte_we,           // PTE write enable
    input  logic [19:0] vpn_write, // VPN to write
    input  logic [31:0] pte_write  // PTE value to write

    // Mutex for exclusive access
    input  logic pte_mutex,         // Page table mutex (high = exclusive access)
    output logic pte_mutex_grant   // Mutex grant signal
);
```

**Design Notes**:
- **Simple Interface**: Clear read/write operations
- **Automatic Bit Updates**: Dirty/access bits updated automatically on access
- **Educational Value**: Easy to understand PTE update semantics

**PTE Format** (32 bits):
```
[19:0] PFN    - Physical Frame Number
[20]  Dirty   - Dirty bit
[21]  Reserved
[22]  Access  - Access bit
[23]  W       - Write bit
[24]  R       - Read bit
[25]  Valid   - Valid bit
[26:31] Reserved
```

### 3. `rtl/mmu/page_walker.sv` - Page Table Walker

**Purpose**: Walk page table on TLB miss to find or create translation.

**Interface**:
```systemverilog
module page_walker #(
    parameter PTE_WIDTH = 32
)(
    input  logic clk,
    input  logic rst_n,

    // Input
    input  logic [19:0] vpn,        // Virtual page number to translate
    input  logic [2:0] page_size,   // Page size (0=4KB only for RV32I)
    input  logic pte_mutex_req,     // Request mutex
    output logic pte_mutex_grant,   // Grant mutex

    // Output
    output logic [19:0] pfn,        // Physical frame number
    output logic valid,             // Translation valid
    output logic page_fault,        // Page fault occurred
    output logic [2:0] perm,        // Permissions
    output logic stall,             // Stall signal for pipeline

    // Page table access
    output logic pte_read,          // Read PTE
    output logic [19:0] pte_vpn,    // VPN to read
    input  logic [31:0] pte_data,   // PTE data returned

    // PTE write (for page fault handling)
    output logic pte_write,         // Write PTE
    output logic [19:0] pte_vpn_w,  // VPN to write
    output logic [31:0] pte_wdata   // PTE value to write
);
```

**Design Notes**:
- **Already Pipelined**: Naturally pipelined, no additional multiplexing needed
- **Simple Interface**: Clear stage separation
- **Educational Value**: Easy to trace page walk progression

### 4. `rtl/mmu/addr_translator.sv` - Address Translation

**Purpose**: Main address translation logic, coordinating TLB and page walker.

**Interface**:
```systemverilog
module addr_translator #(
    parameter TLB_ENTRIES = 16,
    parameter PTE_WIDTH = 32
)(
    input  logic clk,
    input  logic rst_n,

    // Virtual address input
    input  logic [31:0] vaddr,      // Virtual address to translate

    // Page size selection
    input  logic [2:0] page_size,   // 0=4KB (only for RV32I)

    // Translation output
    output logic [31:0] paddr,      // Physical address
    output logic tlb_hit,           // TLB hit
    output logic page_fault,        // Page fault
    output logic [2:0] perm,        // Permissions
    output logic stall,             // Stall signal for pipeline

    // TLB interface (time-multiplexed)
    output logic tlb_read,          // TLB read
    output logic [19:0] tlb_vpn,    // VPN to read
    output logic [3:0] tlb_idx,     // Which 4 entries to compare
    output logic [3:0] tlb_valid,   // Valid entries in group
    input  logic tlb_hit_n,         // TLB hit (active low)
    input  logic [31:0] tlb_paddr,  // TLB physical address

    output logic pte_read,          // Page table read
    output logic [19:0] pte_vpn,    // VPN to read
    input  logic [31:0] pte_data,   // PTE data

    output logic pte_write,         // Page table write
    output logic [19:0] pte_vpn_w,  // VPN to write
    output logic [31:0] pte_wdata   // PTE value

);
```

**Design Notes**:
- **Simple Control**: Clear coordination between TLB and page walker
- **Time-Multiplexed TLB**: 4 cycles for full TLB scan
- **Educational Value**: Easy to understand translation flow

### 5. `rtl/mmu/mmu_control.sv` - MMU Control

**Purpose**: Control signals and status for MMU operations.

**Interface**:
```systemverilog
module mmu_control (
    input  logic clk,
    input  logic rst_n,

    // Mode selection
    input  logic spp,               // SPP bit (1=supervisor, 0=user)
    input  logic sum,               // SUM bit (1=virtual memory enabled)

    // Trap vector configuration
    input  logic [31:0] stvec,      // Supervisor trap vector
    input  logic [31:0] mtvec,      // Machine trap vector

    // Status output
    output logic [31:0] scause,     // Supervisor cause
    output logic [31:0] stval,      // Supervisor trap value
    output logic [31:0] sepc,       // Supervisor PC
    output logic [31:0] mcause,     // Machine cause
    output logic [31:0] mtval,      // Machine trap value
    output logic [31:0] mepc,       // Machine PC
    output logic [31:0] mscratch,   // Machine scratch
    output logic [31:0] sscratch,   // Supervisor scratch
    output logic [31:0] sbadaddr,   // Supervisor bad address

    // Interrupt status
    output logic [31:0] sip,        // Supervisor interrupt pending
    output logic [31:0] sie,        // Supervisor interrupt enable
    output logic [31:0] mie,        // Machine interrupt enable
    output logic [31:0] mip,        // Machine interrupt pending

    // Address translation control
    output logic [31:0] satp,       // Supervisor address translation and protection

    // PMP control
    output logic [31:0] pmpcfg0,    // PMP configuration register 0
    output logic [31:0] pmpaddr0,   // PMP address register 0
    output logic [31:0] pmpcfg1,    // PMP configuration register 1
    output logic [31:0] pmpaddr1,   // PMP address register 1
    output logic [31:0] pmpcfg2,    // PMP configuration register 2
    output logic [31:0] pmpaddr2,   // PMP address register 2
    output logic [31:0] pmpcfg3,    // PMP configuration register 3
    output logic [31:0] pmpaddr3,   // PMP address register 3
    output logic [31:0] pmpcfg4,    // PMP configuration register 4
    output logic [31:0] pmpaddr4,   // PMP address register 4
    output logic [31:0] pmpcfg5,    // PMP configuration register 5
    output logic [31:0] pmpaddr5,   // PMP address register 5
    output logic [31:0] pmpcfg6,    // PMP configuration register 6
    output logic [31:0] pmpaddr6,   // PMP address register 6
    output logic [31:0] pmpcfg7,    // PMP configuration register 7
    output logic [31:0] pmpaddr7,   // PMP address register 7
    output logic [31:0] pmpcfg8,    // PMP configuration register 8
    output logic [31:0] pmpaddr8,   // PMP address register 8
    output logic [31:0] pmpcfg9,    // PMP configuration register 9
    output logic [31:0] pmpaddr9,   // PMP address register 9
    output logic [31:0] pmpcfg10,   // PMP configuration register 10
    output logic [31:0] pmpaddr10,  // PMP address register 10
    output logic [31:0] pmpcfg11,   // PMP configuration register 11
    output logic [31:0] pmpaddr11,  // PMP address register 11
    output logic [31:0] pmpcfg12,   // PMP configuration register 12
    output logic [31:0] pmpaddr12,  // PMP address register 12
    output logic [31:0] pmpcfg13,   // PMP configuration register 13
    output logic [31:0] pmpaddr13,  // PMP address register 13
    output logic [31:0] pmpcfg14,   // PMP configuration register 14
    output logic [31:0] pmpaddr14,  // PMP address register 14
    output logic [31:0] pmpcfg15,   // PMP configuration register 15
    output logic [31:0] pmpaddr15   // PMP address register 15

);
```

**Design Notes**:
- **Simple Interface**: Clear control/status signals
- **Educational Value**: Easy to understand MMU control flow
- **Reset Sequence**: SATP initialized to 0x00000000 on reset

### 6. `rtl/mmu/pmp.sv` - Physical Memory Protection

**Purpose**: Hardware-enforced memory protection using PMP regions.

**Interface**:
```systemverilog
module pmp (
    input  logic clk,
    input  logic rst_n,

    // Physical address input
    input  logic [31:0] paddr,      // Physical address to check

    // Access type
    input  logic is_load,           // Load access
    input  logic is_store,          // Store access
    input  logic is_instruction,    // Instruction fetch

    // PMP registers (read-only from this module)
    input  logic [31:0] pmpcfg0,     // PMP config 0
    input  logic [31:0] pmpaddr0,    // PMP addr 0
    input  logic [31:0] pmpcfg1,     // PMP config 1
    input  logic [31:0] pmpaddr1,    // PMP addr 1
    input  logic [31:0] pmpcfg2,     // PMP config 2
    input  logic [31:0] pmpaddr2,    // PMP addr 2
    input  logic [31:0] pmpcfg3,     // PMP config 3
    input  logic [31:0] pmpaddr3,    // PMP addr 3
    input  logic [31:0] pmpcfg4,     // PMP config 4
    input  logic [31:0] pmpaddr4,    // PMP addr 4
    input  logic [31:0] pmpcfg5,     // PMP config 5
    input  logic [31:0] pmpaddr5,    // PMP addr 5
    input  logic [31:0] pmpcfg6,     // PMP config 6
    input  logic [31:0] pmpaddr6,    // PMP addr 6
    input  logic [31:0] pmpcfg7,     // PMP config 7
    input  logic [31:0] pmpaddr7,    // PMP addr 7
    input  logic [31:0] pmpcfg8,     // PMP config 8
    input  logic [31:0] pmpaddr8,    // PMP addr 8
    input  logic [31:0] pmpcfg9,     // PMP config 9
    input  logic [31:0] pmpaddr9,    // PMP addr 9
    input  logic [31:0] pmpcfg10,    // PMP config 10
    input  logic [31:0] pmpaddr10,   // PMP addr 10
    input  logic [31:0] pmpcfg11,    // PMP config 11
    input  logic [31:0] pmpaddr11,   // PMP addr 11
    input  logic [31:0] pmpcfg12,    // PMP config 12
    input  logic [31:0] pmpaddr12,   // PMP addr 12
    input  logic [31:0] pmpcfg13,    // PMP config 13
    input  logic [31:0] pmpaddr13,   // PMP addr 13
    input  logic [31:0] pmpcfg14,    // PMP config 14
    input  logic [31:0] pmpaddr14,   // PMP addr 14
    input  logic [31:0] pmpcfg15,    // PMP config 15
    input  logic [31:0] pmpaddr15    // PMP addr 15

    // Violation output
    output logic pmp_violation,     // PMP violation detected
    output logic [2:0] pmp_cause,   // Violation cause (0=none, 1=load, 2=store, 3=fetch)
    output logic [3:0] pmp_region   // Violating region (0-15)
);
```

**Design Notes**:
- **Hierarchical Check**: 3-stage check (mode → region → address)
- **Simple Interface**: Clear violation reporting
- **Educational Value**: Easy to understand PMP check flow
- **Priority**: Lower region number has higher priority

## CSR Extensions

### S-Mode CSRs

| CSR | Address | Name | Description |
|-----|---------|------|-------------|
| 0x100 | SSTATUS | Status | Supervisor status register |
| 0x104 | SIP | Supervisor Interrupt Pending | Supervisor interrupt pending bits |
| 0x105 | STVEC | Supervisor Trap Vector | Supervisor exception entry point |
| 0x105 | SIE | Supervisor Interrupt Enable | Supervisor interrupt enable bits |
| 0x140 | SCAUSE | Supervisor Cause | Supervisor exception cause |
| 0x141 | SEPC | Supervisor Exception PC | Supervisor exception program counter |
| 0x142 | SSCRATCH | Supervisor Scratch | Supervisor scratch register |
| 0x143 | SBADADDR | Supervisor Bad Address | Supervisor bad address |
| 0x159 | SATP | Supervisor Address Translation | Address translation and protection |
| 0x341 | MIDELEG | Machine Interrupt Delegation | Machine interrupt delegation |
| 0x342 | MEDELEG | Machine Exception Delegation | Machine exception delegation |

### M-Mode CSRs

| CSR | Address | Name | Description |
|-----|---------|------|-------------|
| 0x300 | MSTATUS | Machine Status | Machine mode status register |
| 0x304 | MIE | Machine Interrupt Enable | Machine interrupt enable |
| 0x305 | MTVEC | Machine Trap Vector | Machine exception entry point |
| 0x340 | MEPC | Machine Exception PC | Machine exception program counter |
| 0x342 | MCAUSE | Machine Exception Cause | Machine exception cause |
| 0x343 | MTVAL | Machine Trap Value | Machine trap value |
| 0x343 | MSCRATCH | Machine Scratch | Machine scratch register |
| 0x344 | MIP | Machine Interrupt Pending | Machine interrupt pending bits |
| 0x345 | MIDELEG | Machine Interrupt Delegation | Machine interrupt delegation |
| 0x346 | MEDELEG | Machine Exception Delegation | Machine exception delegation |

### PMP CSRs

| CSR | Address | Name | Description |
|-----|---------|------|-------------|
| 0x3A0 | PMPADDR0 | PMP Address 0 | Physical memory protection address 0 |
| 0x3A1 | PMPADDR1 | PMP Address 1 | Physical memory protection address 1 |
| 0x3A2 | PMPADDR2 | PMP Address 2 | Physical memory protection address 2 |
| 0x3A3 | PMPADDR3 | PMP Address 3 | Physical memory protection address 3 |
| 0x3A4 | PMPADDR4 | PMP Address 4 | Physical memory protection address 4 |
| 0x3A5 | PMPADDR5 | PMP Address 5 | Physical memory protection address 5 |
| 0x3A6 | PMPADDR6 | PMP Address 6 | Physical memory protection address 6 |
| 0x3A7 | PMPADDR7 | PMP Address 7 | Physical memory protection address 7 |
| 0x3A8 | PMPADDR8 | PMP Address 8 | Physical memory protection address 8 |
| 0x3A9 | PMPADDR9 | PMP Address 9 | Physical memory protection address 9 |
| 0x3AA | PMPADDR10 | PMP Address 10 | Physical memory protection address 10 |
| 0x3AB | PMPADDR11 | PMP Address 11 | Physical memory protection address 11 |
| 0x3AC | PMPADDR12 | PMP Address 12 | Physical memory protection address 12 |
| 0x3AD | PMPADDR13 | PMP Address 13 | Physical memory protection address 13 |
| 0x3AE | PMPADDR14 | PMP Address 14 | Physical memory protection address 14 |
| 0x3AF | PMPADDR15 | PMP Address 15 | Physical memory protection address 15 |
| 0x3B0 | PMPCFG0 | PMP Config 0 | PMP configuration register 0 |
| 0x3B1 | PMPCFG1 | PMP Config 1 | PMP configuration register 1 |
| 0x3B2 | PMPCFG2 | PMP Config 2 | PMP configuration register 2 |
| 0x3B3 | PMPCFG3 | PMP Config 3 | PMP configuration register 3 |
| 0x3B4 | PMPCFG4 | PMP Config 4 | PMP configuration register 4 |
| 0x3B5 | PMPCFG5 | PMP Config 5 | PMP configuration register 5 |
| 0x3B6 | PMPCFG6 | PMP Config 6 | PMP configuration register 6 |
| 0x3B7 | PMPCFG7 | PMP Config 7 | PMP configuration register 7 |
| 0x3B8 | PMPCFG8 | PMP Config 8 | PMP configuration register 8 |
| 0x3B9 | PMPCFG9 | PMP Config 9 | PMP configuration register 9 |
| 0x3BA | PMPCFG10 | PMP Config 10 | PMP configuration register 10 |
| 0x3BB | PMPCFG11 | PMP Config 11 | PMP configuration register 11 |
| 0x3BC | PMPCFG12 | PMP Config 12 | PMP configuration register 12 |
| 0x3BD | PMPCFG13 | PMP Config 13 | PMP configuration register 13 |
| 0x3BE | PMPCFG14 | PMP Config 14 | PMP configuration register 14 |
| 0x3BF | PMPCFG15 | PMP Config 15 | PMP configuration register 15 |

## Address Translation Details

### Virtual Address Format (32-bit)

```
[31:14] VPN[19:2]  - Virtual Page Number (20 bits)
[13:12] ASID[3:0]   - Address Space ID (4 bits)
[11:0]  Page Offset - Page offset (12 bits)
```

### Page Sizes

| Page Size | Offset Bits | VPN Bits | PFN Bits |
|-----------|-------------|----------|----------|
| 4KB       | 12          | 20       | 20       |

**Note**: Only 4KB pages are supported for RV32I.

### Page Table Entry Format

```
[19:0] PFN    - Physical Frame Number
[20]  Dirty   - Dirty bit
[21]  Reserved
[22]  Access  - Access bit
[23]  W       - Write bit
[24]  R       - Read bit
[25]  Valid   - Valid bit
[26:31] Reserved
```

### Permission Encoding

| Value | R | W | X | Description |
|-------|---|---|---|-------------|
| 0     | 0 | 0 | 0 | No access |
| 1     | 1 | 0 | 0 | Read-only |
| 2     | 0 | 1 | 0 | Write-only |
| 3     | 1 | 1 | 0 | Read-write |
| 4     | 1 | 0 | 1 | Execute-only |
| 5     | 1 | 1 | 1 | Read-write-execute |

## Satp Register Format

The Supervisor Address Translation and Protection (satp) register controls address translation:

```
[31:29] Mode     - Address translation mode (0=none, 1=sv32)
[28:0]  Asid[3:0]|SatpMode - Address Space ID and mode
```

For sv32 mode:
```
[31:14] 0        - Reserved
[13:12] ASID[3:0] - Address Space ID
[11:0]  0        - Reserved
```

## PMP Configuration Format

Each PMP register pair (PMPADDRn, PMPCFGn) defines a memory protection region:

```
PMPCFG Format:
[31:28] TOR     - Top of region (1=enabled, 0=disabled)
[27:24] NAT     - Non-aligned top (1=top is not aligned)
[23:20] LOR     - Length of region (0=4B, 1=8B, ..., 7=64KB)
[19:16] NR      - Non-aligned length (1=length is not aligned)
[15:12] A       - Alignment (0=offset, 1=aligned)
[11:8]  L       - Length (0=4B, 1=8B, ..., 7=64KB)
[7:4]   X       - Execute permission (0=none, 1=instruction)
[3:0]   R       - Read/write permission (0=none, 1=read, 2=write, 3=read-write)
```

## FSM State Additions

Add the following states to the control FSM for MMU operations:

```systemverilog
// MMU States
TLB_HIT,           // TLB hit, use translated address
TLB_MISS,          // TLB miss, walk page table
PAGE_FAULT_0,      // Page fault detected, save context
PAGE_FAULT_1,      // Page fault, write mepc/mcause/mtval
PAGE_FAULT_2,      // Page fault, jump to handler
PMP_VIOLATION,     // PMP violation, trigger trap
```

## Gap Analysis and Additions

This section addresses critical coverage gaps identified through 5-whys analysis of the MMU specification.

---

### 1. TLB Conflict Handling (Direct-Mapped Limitation)

**Gap**: Direct-mapped TLBs can cause conflicts when two VPNs map to the same TLB entry.

**Resolution**:
- **Conflict Detection**: On TLB access, compute expected index = VPN[19:16]
- **Conflict Resolution**: If entry exists but VPN mismatch, treat as TLB miss
- **Behavior**: On conflict, invalidate the conflicting entry and perform refill

```systemverilog
// TLB index calculation
assign tlb_index = vpn[19:16];

// Conflict detection
assign tlb_conflict = tlb_valid && (tlb_vpn != vpn) && (tlb_index == vpn[19:16]);

// TLB hit only if valid AND no conflict
assign tlb_hit = tlb_valid && (tlb_vpn == vpn) && !tlb_conflict;
```

**Rationale**: Direct-mapped TLBs inherently have conflicts; treating conflicts as misses ensures correctness at the cost of occasional refill latency.

---

### 2. TLB Refill Failure Modes

**Gap**: No handling for TLB miss when all entries are full, or when page walk fails.

**Resolution**:
- **Full TLB Handling**: If all 16 entries are valid, invalidate the lowest-indexed entry (round-robin)
- **Page Walk Failure**: If page walk fails (invalid PTE, invalid PFN), trigger page fault
- **Invalid PFN Handling**: If PFN exceeds physical memory bounds, trigger page fault

```systemverilog
// Round-robin invalidation for full TLB
always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
        tlb_rr_idx <= 4'd0;
    else if (tlb_refill_needed && tlb_all_valid)
        tlb_rr_idx <= tlb_rr_idx + 1;
end

// Invalidation target
assign tlb_invalidate_idx = tlb_rr_idx;

// Page walk failure detection
assign page_walk_failed = !pte_valid || pte_pfn > max_pfn;
```

**Rationale**: Ensures TLB always has space for new entries and handles physical memory bounds.

---

### 3. PTE Update Semantics

**Gap**: No specification of dirty/access bit handling on PTE write.

**Resolution**:
- **Dirty Bit**: Automatically set on write access to PTE
- **Access Bit**: Automatically set on any PTE read or write
- **Permission Bits**: Updated from perm_write input
- **Valid Bit**: Preserved on update, set to 0 on invalidation

```systemverilog
// PTE update logic
always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
        pte_dirty <= 1'b0;
    else if (pte_we && pte_mutex) begin
        pte_dirty <= 1'b1;  // Set dirty on write
        pte_access <= 1'b1; // Set access on any access
        pte_r <= perm_write[1];
        pte_w <= perm_write[0];
        pte_x <= perm_write[2];
        pte_valid <= valid;
        pte_pfn <= pfn;
    end
end
```

**Rationale**: Automatic bit updates ensure correct tracking of page usage.

---

### 4. Mutex Timeout and Deadlock Prevention

**Gap**: Single mutex for all operations without safeguards against deadlock.

**Resolution**:
- **Timeout Mechanism**: Mutex request timeout after 10 cycles
- **Priority Inversion Prevention**: Highest priority operation (TLB refill) gets mutex first
- **Deadlock Detection**: Timeout triggers error signal

```systemverilog
// Mutex timeout counter
always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
        mutex_timeout_cnt <= 10'd0;
    else if (pte_mutex_req && !pte_mutex_grant)
        mutex_timeout_cnt <= mutex_timeout_cnt + 1;
    else
        mutex_timeout_cnt <= 10'd0;
end

// Timeout detection
assign mutex_timeout = mutex_timeout_cnt >= 10'd10;

// Priority: TLB refill > PTE update
assign pte_mutex_grant = (pte_mutex && (tlb_refill_priority || pte_update_priority));
```

**Rationale**: Prevents system hang from mutex deadlock and ensures critical operations complete.

---

### 5. Page Fault Handler Requirements

**Gap**: No specification of what happens if handler faults again, or if handler is not set.

**Resolution**:
- **Handler Not Set**: If STVEC/MTVEC is 0, trigger double fault (cause=0x8)
- **Double Fault**: Save current state to MSCRATCH/SSCRATCH, halt execution
- **Nested Faults**: Each fault increments fault_nest_count; max depth = 32

```systemverilog
// Trap vector validation
assign trap_vector_valid = (stvec != 0) || (mtvec != 0);

// Double fault detection
assign double_fault = page_fault && !trap_vector_valid;

// Fault nesting counter
always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
        fault_nest_count <= 1'd0;
    else if (page_fault)
        fault_nest_count <= fault_nest_count + 1;
    else if (fault_handler_complete)
        fault_nest_count <= fault_nest_count - 1;
end

// Max nesting depth
assign fault_overflow = fault_nest_count >= 1'd32;
```

**Rationale**: Prevents infinite fault loops and provides clear error indication.

---

### 6. Multi-cycle Instruction Fault Detection

**Gap**: No mechanism to detect multi-cycle instructions or track instruction completion.

**Resolution**:
- **Instruction Type Detection**: Use decoder output to identify multi-cycle instructions
- **Completion Tracking**: Maintain instruction completion status per pipeline stage
- **PC Save Timing**: Save PC at instruction decode stage for multi-cycle instructions

```systemverilog
// Multi-cycle instruction detection
assign is_multi_cycle = decoder_multicycle;

// PC save timing
always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
        sepc_save <= 32'd0;
    else if (page_fault && is_multi_cycle)
        sepc_save <= vaddr;  // Save at decode, not execute
    else if (fault_handler_complete)
        sepc_save <= 32'd0;
end
```

**Rationale**: Ensures correct PC save for multi-cycle instructions by saving at decode stage.

---

### 7. PMP vs TLB Conflict Resolution

**Gap**: No specification of what happens when PMP and TLB disagree.

**Resolution**:
- **Priority**: PMP violation takes precedence over TLB hit
- **Check Order**: PMP check performed after TLB translation
- **Violation Reporting**: Report both TLB hit and PMP violation if both occur

```systemverilog
// PMP takes precedence
assign final_access_allowed = tlb_hit && !pmp_violation;

// Combined violation reporting
assign combined_violation = pmp_violation || page_fault;
assign violation_type = pmp_violation ? 2 : 1;  // 2=PMP, 1=TLB fault
```

**Rationale**: PMP is a lower-level protection mechanism and should take precedence.

---

### 8. PMP Region Priority

**Gap**: No handling for overlapping PMP regions or region priority.

**Resolution**:
- **Priority Order**: Lower region number has higher priority (0 > 1 > ... > 15)
- **Overlap Handling**: First matching region determines access permissions
- **No Match**: If no region matches, treat as no access

```systemverilog
// Region priority check (lower index = higher priority)
always_comb begin
    pmp_violation = 1'b0;
    pmp_region = 4'd16;  // No match
    pmp_cause = 3'd0;

    for (int i = 0; i < 16; i++) begin
        if (pmp_cfg[i].tor && pmp_addr_match(paddr, pmp_cfg[i], pmp_access)) begin
            pmp_violation = pmp_cfg[i].check_access(pmp_access);
            pmp_region = i;
            pmp_cause = pmp_access_to_cause(pmp_access);
            break;  // First match wins
        end
    end
end
```

**Rationale**: Deterministic priority ensures consistent behavior on overlapping regions.

---

### 9. ASID Management

**Gap**: Only 4 bits (16 contexts) but no management policy.

**Resolution**:
- **ASID Allocation**: OS sets ASID via TLB maintenance instructions
- **ASID Recycling**: On context switch, recycle ASID if no TLB entries use it
- **ASID Overflow**: If ASID=15 (all bits used), flush all TLB entries

```systemverilog
// ASID overflow detection
assign asid_overflow = asid == 4'd15;

// ASID recycling on context switch
always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
        tlb_asid <= 4'd0;
    else if (context_switch && !asid_in_use)
        tlb_asid <= new_asid;
    else if (asid_overflow)
        flush_all_tlb();
end

// Track ASID usage
assign asid_in_use = any_entry_has_asid(tlb_asid);
```

**Rationale**: Prevents ASID exhaustion and ensures correct context isolation.

---

### 10. CSR Access Control

**Gap**: No CSR read/write permissions or access exception handling.

**Resolution**:
- **S-mode CSRs**: S-mode can read/write S-mode CSRs; M-mode CSRs require SPP=0
- **M-mode CSRs**: M-mode can read/write M-mode CSRs; S-mode CSRs require SPP=1
- **Access Exceptions**: Invalid CSR access triggers exception (cause=0xC)

```systemverilog
// CSR access permission check
assign csr_access_valid = (csr_addr < 0x300) ||
                          (csr_addr >= 0x300 && csr_addr < 0x380 && spp == 1) ||
                          (csr_addr >= 0x380 && spp == 0);

// CSR access exception
assign csr_access_exception = csr_write && !csr_access_valid;
```

**Rationale**: Enforces privilege separation for CSR access.

---

### 11. SATP Mode Validation

**Gap**: No validation for invalid SATP mode values.

**Resolution**:
- **Valid Modes**: Mode 0 (no translation) and Mode 1 (sv32) only
- **Invalid Mode**: Any other mode triggers exception (cause=0x10)
- **Mode Change**: Mode change requires TLB flush

```systemverilog
// SATP mode validation
assign satp_mode_valid = (satp[31:29] == 3'd0) || (satp[31:29] == 3'd1);

// Invalid mode detection
assign satp_mode_invalid = !satp_mode_valid && satp[31:29] != 3'd0;

// Mode change handling
assign tlb_flush_on_mode_change = satp_mode_invalid;
```

**Rationale**: Prevents undefined behavior from invalid mode values.

---

### 12. Physical Memory Limits

**Gap**: No handling for physical memory less than 4GB.

**Resolution**:
- **PFN Bounds Check**: PFN must be < (physical_memory_size / 4KB)
- **Configurable Limit**: MAX_PFN configurable at compile time
- **Overflow Handling**: PFN >= MAX_PFN triggers page fault

```systemverilog
// Physical memory size configuration
parameter MAX_PFN = 1024;  // 4GB / 4KB = 1M, but can be reduced

// PFN bounds check
assign pfn_valid = pte_pfn < MAX_PFN;

// Overflow detection
assign pfn_overflow = pte_pfn >= MAX_PFN;
```

**Rationale**: Allows configuration for systems with less than 4GB physical memory.

---

### 13. TLB Invalidation Triggers

**Gap**: Only mentions privilege mode change; no other invalidation triggers.

**Resolution**:
- **Privilege Mode Change**: S-mode <-> M-mode switch
- **ASID Change**: New ASID requires TLB flush
- **SATP Mode Change**: Mode 0 <-> Mode 1 switch
- **Exception Entry**: Page fault or PMP violation
- **Software Flush**: TSB (TLB Shootdown) instruction

```systemverilog
// Invalidation trigger OR
assign tlb_invalidate = privilege_mode_change ||
                        asid_change ||
                        satp_mode_change ||
                        exception_entry ||
                        tlb_flush_request;

// Mode change detection
assign satp_mode_change = old_satp[31:29] != new_satp[31:29];
```

**Rationale**: Ensures TLB consistency across all context changes.

---

### 14. Page Table Overflow

**Gap**: No handling for more than 1M page table entries.

**Resolution**:
- **Overflow Detection**: VPN >= 2^20 triggers exception
- **Sparse Handling**: Unused entries return invalid PTE
- **Compression**: Future extension for sparse page tables

```systemverilog
// VPN bounds check
assign vpn_valid = vpn < 20'd1048576;

// Overflow detection
assign page_table_overflow = vpn >= 20'd1048576;

// Invalid PTE for unused entries
assign pte_invalid = !pte_valid || vpn >= 20'd1048576;
```

**Rationale**: Prevents out-of-bounds page table access.

---

### 15. Nested Page Walks

**Gap**: No handling for concurrent page walks during a page walk.

**Resolution**:
- **Serialization**: Page walker uses mutex for exclusive access
- **Nested Walk Prevention**: If walk in progress, wait for completion
- **Timeout**: Walk timeout after 100 cycles triggers error

```systemverilog
// Walk in progress flag
assign walk_in_progress = page_walker_busy;

// Nested walk prevention
assign pte_mutex_grant = pte_mutex && !walk_in_progress;

// Walk timeout
always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
        walk_timeout_cnt <= 100'd0;
    else if (page_walker_busy && !walk_complete)
        walk_timeout_cnt <= walk_timeout_cnt + 1;
    else
        walk_timeout_cnt <= 100'd0;
end

assign walk_timeout = walk_timeout_cnt >= 100'd100;
```

**Rationale**: Prevents deadlock and ensures walk completion.

---

### 16. CSR Synchronization

**Gap**: No CSR read/write serialization or synchronization.

**Resolution**:
- **Serialization**: CSR access serialized by csr_mutex
- **Conflict Detection**: csr_busy flag prevents concurrent access
- **Priority**: Exception-related CSR access has highest priority

```systemverilog
// CSR mutex
always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
        csr_mutex <= 1'b0;
    else if (csr_mutex_req && !csr_mutex_grant)
        csr_mutex <= 1'b1;
    else if (csr_access_complete)
        csr_mutex <= 1'b0;
end

// Priority: Exception CSRs > Normal CSRs
assign csr_mutex_grant = csr_mutex && (exception_csr || normal_csr);
```

**Rationale**: Prevents race conditions on CSR access.

---

### 17. Double-Fault Handling

**Gap**: No specification for handler fault behavior.

**Resolution**:
- **Double Fault Cause**: MCAUSE = 0x8 (double fault)
- **State Capture**: Save SEPC, MTVAL, MCAUSE to MSCRATCH
- **Halt Execution**: After double fault, halt processor
- **Debug Mode**: If debug enabled, break to debugger

```systemverilog
// Double fault detection
assign double_fault = page_fault && !trap_vector_valid;

// State capture
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        mscratch <= 32'd0;
        mcause <= 32'd0;
    end else if (double_fault) begin
        mscratch <= sepc;
        mcause <= 32'd8;  // Double fault cause
        mtval <= stval;
        halt_execution <= 1'b1;
    end
end
```

**Rationale**: Provides clear error indication and prevents infinite loops.

---

### 18. PMP Mode Validation

**Gap**: No validation for invalid PMP mode values.

**Resolution**:
- **Valid Modes**: TOR (1), NAPO (2), OFF (3) only
- **Invalid Mode**: Any other value triggers exception
- **Mode Change**: Mode change may require TLB flush

```systemverilog
// PMP mode validation
assign pmp_mode_valid = (pmp_cfg[31:28] == 4'd1) ||
                        (pmp_cfg[31:28] == 4'd2) ||
                        (pmp_cfg[31:28] == 4'd3);

// Invalid mode detection
assign pmp_mode_invalid = !pmp_mode_valid;

// Mode change handling
assign tlb_flush_on_pmp_change = pmp_mode_invalid;
```

**Rationale**: Prevents undefined behavior from invalid PMP modes.

---

### 19. TLB Stall Propagation

**Gap**: No specification of how stall signals propagate through pipeline.

**Resolution**:
- **Stall Signal**: TLB stall propagates to all pipeline stages
- **Bubble Insertion**: Stall cycles insert bubbles in pipeline
- **Stall Acknowledgment**: Pipeline stage acknowledges stall

```systemverilog
// Stall propagation
assign pipeline_stall = tlb_stall || page_fault || pmp_violation;

// Bubble insertion
always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
        pipeline_pc <= 32'd0;
    else if (pipeline_stall)
        pipeline_pc <= pipeline_pc;  // Hold PC (bubble)
    else
        pipeline_pc <= pipeline_pc + 4;  // Normal advance
end
```

**Rationale**: Ensures pipeline correctness during MMU stalls.

---

### 20. Reset Sequence

**Gap**: No SATP initialization sequence or reset timing requirements.

**Resolution**:
- **Reset Value**: SATP = 0x00000000 (no translation)
- **Initialization Order**:
  1. Reset all registers
  2. Initialize page table (optional)
  3. Set SATP to desired mode
  4. Enable virtual memory (SUM bit)
- **Timing**: SATP must be stable before first instruction

```systemverilog
// Reset sequence
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        satp <= 32'd0;  // No translation
        sum <= 1'b0;    // Virtual memory disabled
        spp <= 1'b1;    // Start in supervisor mode
    end else if (reset_complete) begin
        satp <= init_satp;  // From configuration
        sum <= init_sum;    // From configuration
    end
end

// Reset complete flag
always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
        reset_complete <= 1'b0;
    else if (rst_n)
        reset_complete <= 1'b1;
    else if (reset_timer >= 100)
        reset_complete <= 1'b1;
end
```

**Rationale**: Ensures safe boot sequence with proper initialization order.

---

## Summary of Gap Fixes

| # | Gap Category | Fix Summary |
|---|--------------|-------------|
| 1 | TLB Conflict | Conflict detection and resolution |
| 2 | TLB Refill | Round-robin invalidation, page walk failure handling |
| 3 | PTE Update | Automatic dirty/access bit updates |
| 4 | Mutex | Timeout mechanism, priority inversion prevention |
| 5 | Page Fault | Double fault handling, handler failure modes |
| 6 | Multi-cycle | Instruction type detection, PC save timing |
| 7 | PMP/TLB | PMP takes precedence over TLB |
| 8 | PMP Priority | Lower region number has higher priority |
| 9 | ASID | Overflow handling, recycling policy |
| 10 | CSR Access | Permission checks, access exceptions |
| 11 | SATP Mode | Invalid mode validation |
| 12 | Physical Memory | PFN bounds checking |
| 13 | TLB Invalidation | Complete list of flush triggers |
| 14 | Page Table | VPN bounds checking |
| 15 | Nested Walks | Serialization, timeout handling |
| 16 | CSR Sync | Mutex serialization |
| 17 | Double Fault | State capture, halt execution |
| 18 | PMP Mode | Invalid mode validation |
| 19 | Stall Propagation | Pipeline stall handling |
| 20 | Reset Sequence | Initialization order, timing |

---

## Implementation Phases

### Phase 1: Foundation (Days 1-3)
1. Create `rtl/mmu/` directory structure
2. Implement `datatypes.sv` extensions for MMU types
3. Implement `tlb.sv` with basic lookup and conflict handling
4. Implement `page_table.sv` for storage with automatic bit updates

### Phase 2: Address Translation (Days 4-7)
1. Implement `addr_translator.sv` with mutex and timeout
2. Implement `page_walker.sv` with nested walk prevention
3. Integrate TLB with page walker
4. Add virtual address generation in control unit

### Phase 3: CSR Integration (Days 8-10)
1. Extend `csr_file.sv` with S-mode CSRs and access control
2. Add M-mode CSRs
3. Implement PMP CSRs (16 regions) with mode validation
4. Integrate SSTATUS/MSTATUS handling

### Phase 4: Control Unit Integration (Days 11-14)
1. Modify `control.sv` for virtual address generation
2. Add MMU states to FSM
3. Handle page fault recovery with double fault detection
4. Integrate trap vectors with validation

### Phase 5: Testing (Days 15-17)
1. Create MMU testbench
2. Test TLB operations including conflict handling
3. Test page table walks with timeout
4. Test page faults and double faults
5. Test PMP violations with region priority

### Phase 6: Integration & Debug (Days 18-21)
1. Integrate with `core_top.sv`
2. Run existing test suite
3. Debug and fix issues
4. Performance optimization

## References

- [RISC-V Privileged Specification v1.12](https://github.com/riscv-non-privileged/riscv-privileged)
- [RISC-V Instruction Set Manual v2.0](https://github.com/riscv/riscv-asm-manual)
