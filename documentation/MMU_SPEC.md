# MMU Specification for Potato RV32I

## Overview

This document specifies the Memory Management Unit (MMU) implementation for the Potato RV32I processor. The MMU provides full virtual memory support with TLB, sv32 page tables, and Physical Memory Protection (PMP) as defined in the RISC-V Privileged Specification v1.12.

**Scope**: This specification is strictly for RV32I with 32-bit virtual and physical address spaces. RV64/RV128 support is explicitly out of scope.

**Standards Compliance**: All register formats, CSR addresses, and PTE layouts strictly follow RISC-V Privileged Spec v1.12 to ensure compatibility with standard RISC-V operating systems and toolchains.

## Design Decisions and Rationale

### Physical Address Space
- **Size**: 4GB (32-bit physical address space)
- **Rationale**: Matches the 32-bit virtual address space, allowing full 1:1 mapping capability
- **PPN Size**: 22 bits (supports full 4GB physical memory in sv32)

### TLB Design
- **Entries**: 16 entries (fixed)
- **Associativity**: Direct-mapped (1-way)
- **Comparison**: Parallel 1-cycle tag comparison (all 16 entries compared combinationally)
- **Rationale**:
  - 16 entries cover 64MB of virtual address space (for 4KB pages)
  - Direct-mapped is simplest and sufficient for RV32I
  - Parallel comparison maintains single-cycle TLB hit latency without unjustified complexity
  - Fixed size simplifies implementation
- **Refill Policy**: On TLB miss, page walker walks page table and writes to TLB
- **LRU**: Not implemented (direct-mapped)
- **Context Switch**: TLB entries are invalidated on privilege mode change or via SFENCE.VMA

### Page Table Storage
- **Implementation**: Memory-based (stored in physical memory, not flip-flops)
- **Root Pointer**: SATP register contains PPN of root page table (physical address / 4KB)
- **Hierarchy**: Two-level sv32 page table (VPN[1] and VPN[0])
- **Access**: Page walker reads PTEs from memory via existing memory bus
- **Rationale**:
  - Memory-based page tables are synthesizable and standard across all RISC-V systems
  - Follows RISC-V sv32 two-level hierarchy for software compatibility
  - Reuses existing memory interface (mem_addr/mem_rdata/mem_resp)
  - Scalable: OS can create arbitrarily large virtual address spaces

### Page Walker
- **Latency**: Synchronous, multi-cycle operation
- **Hierarchy**: Two-level walk per sv32 standard
- **Concurrent Access**: One translation at a time (serialized by FSM states)
- **Page Fault Handling**: If PTE invalid or access denied, raise page fault exception; software fault handler installs PTE and returns via SRET
- **Rationale**:
  - Multi-cycle walk allows time for memory access (currently 4 cycles default)
  - Hardware only reads PTEs; OS software creates/updates mappings
  - Reduces hardware complexity and matches real OS behavior

### Address Translation
- **Latency**: 1 cycle for TLB hit, multiple cycles for TLB miss (page walk)
- **Rationale**:
  - TLB hit is single cycle (parallel array lookup)
  - TLB miss requires page walk (multiple cycles via memory bus)
- **Serialization**: Page walker serialized via control FSM states (not hardware mutexes)

### Trap Handling
- **sepc Saving**: Save instruction PC at point of fault detection
- **Rationale**:
  - Need accurate PC to resume instruction after fault handling
  - FSM ensures PC is captured at correct stage

### PMP Design
- **Regions**: 16 PMP regions (physical memory protection)
- **Rationale**:
  - Full RISC-V spec compliance (16 regions maximum for RV32)
  - Supports complex memory protection scenarios
- **Check Timing**: PMP check in parallel with TLB for single-cycle violation detection
- **PMP Modes**: Support TOR (top of range), NAPOT (naturally aligned power-of-two), OFF

### CSR Implementation
- **S-mode CSRs**: Complete set per RISC-V Priv Spec v1.12 (SSTATUS, SIP, SIE, STVEC, SSCRATCH, SCAUSE, SEPC, SATP, MIDELEG, MEDELEG)
- **M-mode CSRs**: Complete set per RISC-V Priv Spec v1.12 (MSTATUS, MIE, MTVEC, MEPC, MCAUSE, MTVAL, MSCRATCH, MIP, MIDELEG, MEDELEG)
- **PMP CSRs**: 4 config registers (PMPCFG0-3) + 16 address registers (PMPADDR0-15) per RV32 standard
- **Rationale**:
  - Implement CSRs per RISC-V standard to ensure compatibility
  - Supports exception delegation and interrupt handling
  - CSR read/write is single-cycle where possible

### Virtual Address Format (sv32)
- **Format**: 32-bit virtual address split as:
  ```
  [31:22] VPN[1]      — 10 bits (second-level page table index)
  [21:12] VPN[0]      — 10 bits (first-level page table index)
  [11:0]  Offset      — 12 bits (byte offset within 4KB page)
  ```
- **Page Size**: 4KB only (12-bit offset)
- **ASID**: 9 bits stored in SATP[30:22] (not in virtual address)
- **Rationale**:
  - sv32 is the standard RV32 virtual memory scheme
  - Two-level hierarchy reduces page table size vs flat single-level
  - ASID in SATP allows OS to disable TLB invalidation on context switch (with care)

### SATP Register (Supervisor Address Translation and Protection)
- **Format**:
  ```
  [31]    MODE    — 1 = sv32, 0 = bare (no translation)
  [30:22] ASID    — 9-bit address space identifier
  [21:0]  PPN     — 22-bit physical page number of root page table
  ```
- **Reset Value**: 0x00000000 (no translation, bare addressing)
- **Rationale**:
  - Standard sv32 SATP format from RISC-V Priv Spec
  - MODE bit 31 controls translation (0=off, 1=on)
  - PPN points to root page table in physical memory
  - ASID allows software to reuse TLB across context switches without flush

### FSM Integration
- **New States**: TLB_HIT, TLB_MISS, PAGE_WALK_0, PAGE_WALK_1, PAGE_FAULT_0, PAGE_FAULT_1, PAGE_FAULT_2, PMP_VIOLATION, SFENCE_VMA
- **PAGE_FAULT Latency**: 3 cycles (save context, update CSRs, jump to handler)
- **PAGE_WALK Latency**: 2-4 cycles per memory access (depends on memory latency)
- **PMP Check**: Single cycle (parallel with TLB, checked combinationally)
- **Rationale**:
  - FSM states provide natural serialization without hardware mutexes
  - Multi-cycle page fault allows proper context saving
  - Single-cycle PMP check keeps critical path short

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────────┐
│                        MMU MODULE                                │
├─────────────────────────────────────────────────────────────────┤
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────────────┐   │
│  │   TLB (16)   │  │ Page Walker  │  │  Memory Interface    │   │
│  │  (parallel   │  │ (multi-cycle)│  │  (DRAM/SRAM via      │   │
│  │   1-cycle)   │  │              │  │   mem_addr/rdata)    │   │
│  └──────┬───────┘  └──────┬───────┘  └──────────┬───────────┘   │
│         │                 │                      │               │
│         └────────┬────────┴──────────────────────┘               │
│                  ▼                                               │
│         ┌──────────────────┐                                    │
│         │ Translation Mux  │◄─── Virtual Address (32-bit)        │
│         │ (TLB Hit vs Walk)│                                    │
│         └──────┬───────────┘                                    │
│                │                                                 │
│                ▼                                                 │
│         ┌──────────────┐                                        │
│         │  PMP Check   │◄─── PMP Config (parallel check)         │
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

    // Address translation interface
    input  logic [31:0] vaddr,      // Virtual address
    input  logic [8:0]  asid,       // ASID from SATP
    output logic [31:0] paddr,      // Physical address
    output logic tlb_hit,           // TLB hit signal
    output logic [2:0] perm,        // Permissions (RWX)

    // TLB maintenance interface
    input  logic tlb_we,            // TLB write enable
    input  logic [19:0] vpn,        // VPN to write (VPN[1]:VPN[0])
    input  logic [21:0] ppn,        // PPN to write
    input  logic [2:0] perm_write,  // Permissions to write (RWX)
    input  logic [8:0]  asid_write, // ASID to write
    input  logic sfence_vma,        // SFENCE.VMA - invalidate entry
    input  logic flush_all,         // Flush all TLB entries

    // Pipeline control
    output logic stall              // Stall signal (only on fill)
);
```

**Design Notes**:
- **Parallel Comparison**: All 16 entries compared combinationally in single cycle
- **Conflict Handling**: Direct-mapped TLB treats conflicts as misses (round-robin eviction)
- **ASID Support**: Each entry tagged with ASID for context isolation
- **Simple Interface**: Clear control signals

**TLB Entry Format** (41 bits total):
```
[40:21] PPN[21:0]   — Physical page number (22 bits for 4GB)
[20:1]  VPN[19:0]   — Virtual page number (20 bits)
[0]     Valid       — Valid bit
[Additional] ASID[8:0], Permissions[2:0]
```

### 2. `rtl/mmu/page_walker.sv` - Page Table Walker

**Purpose**: Walk sv32 page table hierarchy to find translations on TLB miss.

**Interface**:
```systemverilog
module page_walker (
    input  logic clk,
    input  logic rst_n,

    // Translation request (from addr_translator or control FSM)
    input  logic [19:0] vpn,        // VPN to translate (VPN[1]:VPN[0])
    input  logic walk_start,        // Start page walk
    output logic walk_busy,         // Walk in progress

    // Root page table pointer
    input  logic [21:0] satp_ppn,   // Root PPN from SATP

    // Output (to TLB)
    output logic [21:0] ppn,        // Resulting PPN
    output logic walk_valid,        // Translation valid
    output logic walk_fault,        // Page fault occurred
    output logic [2:0] perm,        // Permissions (RWX)

    // Memory interface (reads PTEs from memory)
    output logic mem_read,
    output logic [31:0] mem_addr,   // Address of PTE
    input  logic [31:0] mem_rdata,  // PTE data
    input  logic mem_resp           // Memory response valid
);
```

**Design Notes**:
- **Two-Level Walk**: First reads level 1 PTE using VPN[1], then level 0 using VPN[0]
- **Standard PTE Checking**: Validates valid bit, checks access permissions
- **No PTE Creation**: Hardware only reads; software installs PTEs after fault
- **Timeout**: If memory doesn't respond in ~100 cycles, timeout and page fault

### 3. `rtl/mmu/addr_translator.sv` - Address Translation Coordination

**Purpose**: Coordinates TLB and page walker, selects translated address.

**Interface**:
```systemverilog
module addr_translator (
    input  logic clk,
    input  logic rst_n,

    // Virtual address input
    input  logic [31:0] vaddr,      // Virtual address to translate

    // SATP and ASID
    input  logic satp_mode,         // 1 = sv32, 0 = bare
    input  logic [21:0] satp_ppn,   // Root PPN from SATP
    input  logic [8:0] asid,        // ASID from SATP

    // Translation output
    output logic [31:0] paddr,      // Physical address
    output logic tlb_hit,           // TLB hit
    output logic page_fault,        // Page fault occurred
    output logic [2:0] perm,        // Permissions
    output logic stall,             // Stall pipeline

    // TLB interface
    output logic tlb_we,            // TLB write on miss
    output logic tlb_read_en,
    output logic [19:0] tlb_vpn,
    output logic [8:0] tlb_asid,
    input  logic tlb_hit_in,
    input  logic [31:0] tlb_paddr_in,
    input  logic [2:0] tlb_perm_in,

    // Page walker interface
    output logic walker_start,
    input  logic walker_busy,
    input  logic walker_valid,
    input  logic [21:0] walker_ppn,
    input  logic [2:0] walker_perm,
    input  logic walker_fault
);
```

### 4. `rtl/mmu/pmp.sv` - Physical Memory Protection

**Purpose**: Check physical address against PMP regions, parallel with translation.

**Interface**:
```systemverilog
module pmp (
    input  logic clk,
    input  logic rst_n,

    // Physical address to check
    input  logic [31:0] paddr,

    // Access type
    input  logic is_load,
    input  logic is_store,
    input  logic is_instruction,

    // PMP configuration (4 PMPCFG registers, each packing 4 8-bit entries)
    input  logic [31:0] pmpcfg[3:0],   // PMPCFG0-3
    input  logic [31:0] pmpaddr[15:0], // PMPADDR0-15

    // Violation output
    output logic pmp_violation,
    output logic [3:0] pmp_region,      // Violating region (0-15)
    output logic [2:0] pmp_cause        // 0=none, 1=load, 2=store, 3=fetch
);
```

**Design Notes**:
- **Standard Format**: PMPCFG0-3 each contain 4 8-bit region descriptors
  ```
  Each 8-bit descriptor:
  [7]   L    — lock
  [6:5] —    — reserved
  [4:3] A    — address-match mode (0=OFF, 1=TOR, 2=NA4, 3=NAPOT)
  [2]   X    — execute
  [1]   W    — write
  [0]   R    — read
  ```
- **Region Priority**: Lower-numbered regions have higher priority (first match wins)
- **Parallel Check**: All regions checked combinationally in single cycle

## CSR Extensions

### S-Mode CSRs (0x100–0x180)

| Address | Name     | Description |
|---------|----------|-------------|
| 0x100   | SSTATUS  | Supervisor status register |
| 0x104   | SIE      | Supervisor interrupt enable |
| 0x105   | STVEC    | Supervisor trap vector |
| 0x140   | SSCRATCH | Supervisor scratch register |
| 0x141   | SEPC     | Supervisor exception PC |
| 0x142   | SCAUSE   | Supervisor exception cause |
| 0x143   | STVAL    | Supervisor trap value |
| 0x144   | SIP      | Supervisor interrupt pending |
| 0x180   | SATP     | Supervisor address translation and protection |
| 0x303   | MIDELEG  | Machine interrupt delegation |
| 0x302   | MEDELEG  | Machine exception delegation |

### M-Mode CSRs (0x300–0x346)

| Address | Name     | Description |
|---------|----------|-------------|
| 0x300   | MSTATUS  | Machine status register |
| 0x302   | MEDELEG  | Machine exception delegation |
| 0x303   | MIDELEG  | Machine interrupt delegation |
| 0x304   | MIE      | Machine interrupt enable |
| 0x305   | MTVEC    | Machine trap vector |
| 0x340   | MSCRATCH | Machine scratch register |
| 0x341   | MEPC     | Machine exception PC |
| 0x342   | MCAUSE   | Machine exception cause |
| 0x343   | MTVAL    | Machine trap value |
| 0x344   | MIP      | Machine interrupt pending |

### PMP CSRs (Physical Memory Protection)

**PMPCFG Registers** (each packs 4 8-bit region descriptors):

| Address | Name     | Description |
|---------|----------|-------------|
| 0x3A0   | PMPCFG0  | PMP configuration for regions 0–3 |
| 0x3A1   | PMPCFG1  | PMP configuration for regions 4–7 |
| 0x3A2   | PMPCFG2  | PMP configuration for regions 8–11 |
| 0x3A3   | PMPCFG3  | PMP configuration for regions 12–15 |

**PMPADDR Registers**:

| Address | Name      | Description |
|---------|-----------|-------------|
| 0x3B0   | PMPADDR0  | Region 0 address |
| 0x3B1   | PMPADDR1  | Region 1 address |
| ... | ... | ... |
| 0x3BF   | PMPADDR15 | Region 15 address |

**Format Notes**:
- `PMPCFG` registers contain 4 8-bit entries each: `[31:24]` entry 3, `[23:16]` entry 2, `[15:8]` entry 1, `[7:0]` entry 0
- `PMPADDR` registers contain 32-bit address values (top address for TOR, top-aligned base for NAPOT)

## Address Translation Details

### Virtual Address Format (sv32)

```
[31:22] VPN[1]      — Second-level page table index (10 bits)
[21:12] VPN[0]      — First-level page table index (10 bits)
[11:0]  Offset      — Byte offset within 4KB page (12 bits)
```

### Physical Address Format

```
[31:12] PPN[21:0]   — Physical page number (22 bits)
[11:0]  Offset      — Same as virtual offset (12 bits)
```

### Page Sizes

| Page Size | Offset Bits | VPN Bits | PPN Bits |
|-----------|-------------|----------|----------|
| 4KB       | 12          | 20 (2×10)| 22       |

**Note**: Only 4KB pages are supported for RV32I sv32.

### Page Table Entry Format (sv32)

Each PTE is 32 bits with the following layout:

```
[31:10] PPN[21:0]   — Physical page number (22 bits)
[9:8]   RSW         — Reserved for software (2 bits)
[7]     D           — Dirty bit
[6]     A           — Accessed bit
[5]     G           — Global bit (skip ASID check in TLB)
[4]     U           — User-accessible
[3]     X           — Execute permission
[2]     W           — Write permission
[1]     R           — Read permission
[0]     V           — Valid bit
```

### Permission Encoding

The combination of R, W, X bits defines access:

| R | W | X | Meaning |
|---|---|---|---------|
| 0 | 0 | 0 | No access (invalid) |
| 1 | 0 | 0 | Read-only |
| 0 | 1 | 0 | Write-only (invalid per spec) |
| 1 | 1 | 0 | Read-write |
| 0 | 0 | 1 | Execute-only |
| 1 | 0 | 1 | Read-execute |
| 0 | 1 | 1 | Write-execute (invalid per spec) |
| 1 | 1 | 1 | Read-write-execute |

**Note**: The RISC-V spec allows any combination but recommends treating W without R as invalid.

### SATP Register Format

```
[31]    MODE    — 1 = sv32, 0 = bare (no virtual memory)
[30:22] ASID    — Address Space ID (9 bits, 512 unique spaces)
[21:0]  PPN     — Physical Page Number of root page table
```

**Mode Values**:
- `0`: Bare metal (no translation, physical addresses used directly)
- `1`: sv32 (enable virtual memory with 2-level page table)

**Reset Value**: `0x00000000` (bare mode, no translation)

## FSM State Additions

The control FSM adds the following states for MMU operation:

```systemverilog
// Memory address translation states
TLB_HIT,            // TLB hit - use translated address
TLB_MISS,           // TLB miss - start page walk
PAGE_WALK_0,        // Walking level 1 page table
PAGE_WALK_1,        // Walking level 0 page table
PAGE_FAULT_0,       // Page fault: save context
PAGE_FAULT_1,       // Page fault: update CSRs
PAGE_FAULT_2,       // Page fault: jump to handler
PMP_VIOLATION,      // PMP violation: update CSRs
SFENCE_VMA          // SFENCE.VMA: invalidate TLB entry
```

**Timing**:
- TLB_HIT: 1 cycle (combinational)
- TLB_MISS → PAGE_WALK_0/1: 1+ cycles (depends on memory latency)
- PAGE_FAULT_0/1/2: 3 cycles total
- PMP_VIOLATION: 1 cycle

## SFENCE.VMA Instruction

The SFENCE.VMA instruction is used by the OS to invalidate TLB entries after modifying page tables.

**Format**: `SFENCE.VMA rs1, rs2` (I-type, funct7=0x09, funct3=0)

**Semantics**:
- If `rs1 = 0` and `rs2 = 0`: Flush entire TLB
- If `rs1 ≠ 0` and `rs2 = 0`: Flush TLB entries matching VPN in `rs1`
- If `rs1 = 0` and `rs2 ≠ 0`: Flush TLB entries matching ASID in `rs2`
- If both nonzero: Flush entries matching both VPN and ASID

**Implementation**: FSM handles SFENCE.VMA in SFENCE_VMA state, signals TLB to invalidate entries, then returns to next instruction.

## Implementation Notes

### Critical Design Rules

1. **Page Walker Access**: Hardware page walker reads PTEs from memory only. Software (OS fault handler) creates and updates PTEs after receiving page fault exception.

2. **TLB Invalidation Triggers**:
   - Privilege mode change (S-mode ↔ M-mode transition via MRET/SRET)
   - ASID change (when SATP written with new ASID)
   - SATP mode change (switching between bare and sv32)
   - SFENCE.VMA instruction (software explicit invalidation)
   - Exception entry (on any trap, flush TLB to avoid stale entries)

3. **Simultaneous Memory Access**: When page walker is active and needs to read a PTE, that access blocks load/store operations (only one memory transaction at a time due to non-pipelined design).

4. **Performance**: On average workloads:
   - TLB hit rate ~95% expected
   - Each TLB miss costs ~8–12 cycles (2 page walker cycles × 4 memory latency)
   - 16-entry TLB covers 64MB of virtual address space

### Hardware/Software Boundary

| Hardware Responsibility | Software Responsibility |
|-------------------------|------------------------|
| Detect page faults | Create page table hierarchy |
| Walk page tables | Manage page table entries |
| Cache translations (TLB) | Invalidate stale TLB entries (SFENCE.VMA) |
| Check PMP on access | Configure PMP regions |
| Deliver exception on fault | Fault handler (resolve and SRET) |

### Testing Strategy

1. **TLB Operations**: Test TLB hits, misses, refills, eviction
2. **Page Walks**: Test valid and invalid PTEs, permission checks
3. **Page Faults**: Test fault delivery and recovery
4. **PMP**: Test all region modes (TOR, NAPOT) and priorities
5. **SFENCE.VMA**: Test entry-specific and full flushes
6. **Context Switch**: Test ASID-based isolation
7. **Exception Delivery**: Test nested faults, halt on double fault

## References

- [RISC-V Privileged Specification v1.12](https://github.com/riscv-non-privileged/riscv-privileged)
- [RISC-V Unprivileged Specification v20191213](https://github.com/riscv/riscv-spec-ext)
- RISC-V Foundation Technical Committee
