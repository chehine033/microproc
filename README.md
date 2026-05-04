# 16-bit VHDL Microprocessor — Xilinx FPGA

A fully functional, custom-designed 16-bit microprocessor implemented entirely in VHDL, synthesized and deployed on a **Xilinx FPGA board**. Built from first principles as an academic project at ENICarthage (Infotronics Engineering, Tunisia).

The project includes **two complete implementations** of the control unit — one behavioral and one structural — along with a standalone concurrent hardware multiplier.

---

## Project Structure

| File | Description |
|------|-------------|
| `microprocessor_comportmental.vhd` | Behavioral implementation — all datapath components + behavioral FSM controller + top-level `microproc` entity |
| `machine_etat_structurelle.vhd` | Alternative structural FSM controller — pure boolean logic equations, no enumerated states |
| `multiplieur.vhd` | Standalone concurrent 4×4-bit hardware multiplier |

---

## Architecture Overview

The processor follows a classic **accumulator-based von Neumann architecture**. All instructions operate through a single accumulator register, with operands fetched from a 64KB asynchronous read/write RAM.

### Full Datapath

```
         ┌─────────────┐
         │  Async RAM  │ ← 4096 × 16-bit (64KB), R/W, asynchronous
         │  (pre-init) │
         └──────┬──────┘
                │ data bus (16-bit, bidirectional inout)
         ┌──────▼──────┐        ┌────────────┐
         │     IR      │        │     PC     │ ← 12-bit program counter
         │ (Instr Reg) │        │  (clocked) │
         └──────┬──────┘        └──────┬─────┘
          opcode│  addr(11:0)          │ addr(11:0)
                │              ┌───────▼──────┐
                │              │  MUX_12to1   │ ← selA: PC addr vs IR addr
                │              └───────┬──────┘
                │                      │ → RAM address bus
                │
         ┌──────▼──────┐
         │  MUX_16to1  │ ← selB: immediate (zero-extended IR addr) vs RAM data
         └──────┬──────┘
                │ B input
         ┌──────▼──────┐        ┌────────────┐
         │     UAL     │◄───────│    ACC     │ ← Accumulator (A input)
         │    (ALU)    │        │  (clocked) │
         └──────┬──────┘        └────────────┘
                │ ALU result
                └─→ ACC input / PC input / RAM data bus (via buffer1)
         ┌─────────────┐
         │   buffer1   │ ← acc_oe: drives ACC onto RAM data bus for STO
         └─────────────┘
```

---

## Component Breakdown

### `Async_RAM` — 64KB Asynchronous Read/Write Memory
- **4,096 addresses × 16 bits** = 64KB total
- Fully **asynchronous** — no clock dependency, responds immediately to address/WE changes
- Bidirectional `data` bus (`inout`): reads when `we='0'`, writes when `we='1'`, drives high-Z otherwise to avoid bus contention
- Pre-initialized with a 7-instruction program (addresses 0–6) and data operands at addresses 2048–2050

### `PC` — Program Counter
- 12-bit clocked register, loads new address on rising edge when `pc_ld='1'`
- Feeds the RAM address bus via MUX_12to1 during instruction fetch

### `IR` — Instruction Register
- 16-bit clocked register, splits fetched instruction into:
  - `opcode[3:0]` — upper 4 bits → sent to FSM controller
  - `B[11:0]` — lower 12 bits → operand/jump address → fed to MUX_12to1

### `ACC` — Accumulator
- 16-bit clocked register, the sole working register of the processor
- Outputs two status flags to the FSM controller:
  - `accZ` — high when ACC ≠ 0 (used by JNE)
  - `acc15` — MSB of ACC, i.e. sign bit (used by JGE)

### `UAL` — ALU (Unité Arithmétique et Logique)
- 16-bit ALU with 2-bit function select:

| `alufs` | Operation | Purpose |
|---------|-----------|---------|
| `"00"` | Pass B through | LDA — load RAM value into ACC |
| `"11"` | B + 1 | Increment PC after fetch |
| `"10"` | A + B | ADD instruction |
| `"01"` | A − B | SUB instruction |

- Built from generic N-bit `adder` and `subber` components, each structurally composed of cascaded `Full_Adder` / `Full_Subber` instances (ripple-carry design)

### `MUX_12to1` — 12-bit Address Multiplexer
- Controlled by `selA`, selects the RAM address source:
  - `'0'` → PC output (fetch next instruction)
  - `'1'` → IR operand address (memory access or jump target)

### `MUX_16to1` — 16-bit Data Multiplexer
- Controlled by `selB`, selects the ALU B-input:
  - `'0'` → IR address zero-extended to 16 bits (used as immediate for PC increment)
  - `'1'` → data from RAM bus (memory operand for ADD/SUB/LDA)

### `buffer1` — Tri-state Output Buffer
- Drives the accumulator value onto the bidirectional RAM data bus during STO
- Outputs high-Z when `acc_oe='0'`, preventing bus conflict during reads

---

## Instruction Set

Each instruction is **16 bits wide**: `opcode[15:12]` + `operand_address[11:0]`

| Opcode | Mnemonic | Operation |
|--------|----------|-----------|
| `0000` | **LDA** | ACC ← RAM[addr] |
| `0001` | **STO** | RAM[addr] ← ACC |
| `0010` | **ADD** | ACC ← ACC + RAM[addr] |
| `0011` | **SUB** | ACC ← ACC − RAM[addr] |
| `0100` | **JMP** | PC ← addr (unconditional) |
| `0101` | **JGE** | PC ← addr if ACC ≥ 0 (sign bit = 0) |
| `0110` | **JNE** | PC ← addr if ACC ≠ 0 |
| `0111` | **STP** | Halt processor |

### Pre-loaded Program (RAM addresses 0–6)
```
Addr  Instruction            Decoded
────  ─────────────────────  ──────────────────────────────
0     0000 100000000000      LDA  2048   → ACC = RAM[2048] = 4
1     0011 100000000001      SUB  2049   → ACC = ACC - RAM[2049] = 4-4 = 0
2     0110 000000000101      JNE  5      → ACC=0, skip (fall through)
3     0010 100000000010      ADD  2050   → ACC = ACC + RAM[2050] = 0+5 = 5
4     0100 000000000110      JMP  6      → jump to HALT
5     0001 100000000010      STO  2050   → RAM[2050] = ACC (skipped)
6     0111 000000000000      STP        → HALT

Data: RAM[2048]=4, RAM[2049]=4, RAM[2050]=5
```

---

## FSM Control Unit — Two Implementations

### 1. Behavioral FSM (`machine_etat`)
Implemented using VHDL enumerated state types and case statements. Execute cycle:

```
LOAD_INSTRUCTION → INCREMENT_PC → DECODE_OPCODE
    → EXECUTE_ALU_OPERATION   (opcodes ADD, SUB)
    → MEMORY_ACCESS           (opcodes LDA, STO)
    → JUMP_CONDITIONAL        (opcodes JMP, JGE, JNE — conditional on accZ/acc15)
    → HALT_PROCESSOR          (opcode STP — latches forever)
    → LOAD_INSTRUCTION        (next fetch)
```

### 2. Structural FSM (`machine_etat_structurelle`)
Implements the **identical state machine** using only minimized boolean logic equations — no enumerated states, no case statements. State is a raw 4-bit vector and all transitions and outputs are expressed as direct combinational logic:

```vhdl
-- Next-state logic derived from state transition table:
S01 <= (not S0 and not S1 and S2 and not S3 and not opcode0 and not opcode1 and not opcode2)
    or (not S0 and not S1 and S2 and not S3 and opcode0 and opcode1 and opcode2)
    or (S0 and not S1 and not S2 and S3);

-- Output logic example:
RnW    <= (not S1) or (not S3);
acc_ld <= (S2 and S3) or (S1 and not S2) or (S0 and not S3);
```

This structural approach mirrors what synthesis tools produce internally and demonstrates gate-level understanding of finite state machine design — equivalent to manually deriving logic from a Karnaugh map.

---

## Concurrent 4×4-bit Hardware Multiplier

A standalone hardware entity implementing unsigned 4-bit × 4-bit multiplication using purely combinational concurrent logic — **zero clock cycles required**.

### Method: Parallel Partial Product Accumulation
```
A[3:0] × B[3:0] → P[7:0]

Step 1 — Partial products via MUX (A if B[i]=1, else 0000):
  om1 = A × B[0]  →  padded: "0000" & om1        (×2^0)
  om2 = A × B[1]  →  padded: "000"  & om2 & "0"  (×2^1)
  om3 = A × B[2]  →  padded: "00"   & om3 & "00" (×2^2)
  om4 = A × B[3]  →  padded: "0"    & om4 & "000"(×2^3)

Step 2 — Concurrent addition:
  S1 = om1 + om2
  S2 = om3 + om4
  P  = S1  + S2
```

All partial products are generated and summed **simultaneously in hardware**, exploiting FPGA look-up table parallelism for single-cycle combinational multiplication.

---

## How to Run

### Simulation (ModelSim)
1. Create a new project and add all `.vhd` files
2. Compile `microprocessor_comportmental.vhd` first (contains component definitions)
3. Set `microproc` as the top-level simulation entity
4. Run simulation — observe `data`, `adresse`, `s` (ALU output), `accz`, `acc15`, and RAM contents in the waveform viewer to trace instruction execution

### Synthesis (Xilinx Vivado / ISE)
1. Create a new RTL project and add source files
2. Set top-level entity to `microproc`
3. Run Synthesis → Implementation → Generate Bitstream
4. Program the Xilinx FPGA board via JTAG

---

## Tools & Platform

- **Language:** VHDL (IEEE 1076)
- **Simulation:** ModelSim
- **Synthesis & Deployment:** Xilinx Vivado / ISE
- **Target Hardware:** Xilinx FPGA board

---

## Author

**Chehine Melki**  
Computer Engineering — Infotronics  
ENICarthage, Tunisia  
[chehinemelki033@gmail.com](mailto:chehinemelki033@gmail.com) | [github.com/chehine033](https://github.com/chehine033)
