# VHDL State-Machine Microprocessor — Xilinx FPGA

A fully functional, custom-designed microprocessor implemented in VHDL, synthesized and deployed on a **Xilinx FPGA board**. Built from first principles as an academic project at ENICarthage (Infotronics Engineering).

---

## Architecture Overview

The processor is implemented as a **finite state machine (FSM)** with both behavioral and structural VHDL styles. It fetches and executes instructions from an asynchronous RAM, cycling through fetch → decode → execute states.

### Core Components

| Component | Description |
|-----------|-------------|
| **FSM Controller** | State-machine-based fetch/decode/execute cycle |
| **Async RAM** | 4,096 × 16-bit addresses = 64KB, asynchronous read |
| **ALU** | 4-opcode arithmetic & logic unit |
| **Registers** | 3 general-purpose registers + 1 buffer |
| **Multiplexers** | 2 MUXes for datapath control |
| **Program Counter** | Instruction pointer traversing addresses 0–2047 |

---

## Instruction Set

The processor supports an instruction list initialized in RAM, starting at address `0x0000` and extending to `0x07FF` (2,048 entries). Each instruction is 16 bits wide.

The ALU executes one of **4 operation codes**, mapped to the following operations:

- Arithmetic operations (ADD, etc.)
- Logic operations (AND, OR, etc.)
- Data transfer (LOAD/STORE to/from RAM)
- Control flow (conditional branching)

> See `ALU codes.png` and `microprocessor's instruction list.png` for the full opcode table.

---

## RAM Addressing Structure

- **Size:** 4,096 addresses × 16 bits = **64KB**
- **Type:** Asynchronous (no clock dependency on read)
- **Addressing:** Direct memory addressing via program counter and ALU output

> See `microprocessor's async ram addressing structure.png` for the full addressing diagram.

---

## Concurrent 4×4-bit Multiplier

A **separate hardware entity** implementing unsigned 4-bit × 4-bit multiplication using purely combinational (concurrent) logic — no clock cycles required.

### Design

```
A[3:0] × B[3:0] → P[7:0]
```

**Method:** Partial product generation via 4 MUXes, followed by cascaded ripple-carry adders:

```
Partial products:
  om1 = A if B[0]=1 else 0000   → shifted by 0
  om2 = A if B[1]=1 else 0000   → shifted by 1
  om3 = A if B[2]=1 else 0000   → shifted by 2
  om4 = A if B[3]=1 else 0000   → shifted by 3

Final sum:
  S1 = om1 + om2
  S2 = om3 + om4
  P  = S1  + S2
```

**Sub-components:**
- `Full_Adder` — single-bit full adder (behavioral)
- `chaimaoumayma` — 4-bit ripple-carry adder (structural, using Full_Adder instances)
- `adder` — generic N-bit adder (parameterized, used for 8-bit partial sums)
- `mux_4to1` — 4-bit 2-to-1 MUX for partial product selection
- `multiplieur` — top-level entity combining all of the above

> This design exploits FPGA's native parallelism — all partial products are computed simultaneously in hardware.

---

## Files

| File | Description |
|------|-------------|
| `machine d'etat structurelle te5dem.txt` | Main microprocessor FSM — structural & behavioral VHDL |
| `multiplieur.txt` | Concurrent 4×4-bit multiplier VHDL |
| `microprocessor components.png` | Full datapath block diagram |
| `microprocessor's instruction list.png` | Complete instruction set table |
| `microprocessor's async ram addressing structure.png` | RAM addressing architecture |
| `ALU codes.png` | ALU opcode reference table |
| `concurrent multiplier design.png` | Multiplier hardware diagram |

> **Note:** `.txt` files contain valid VHDL source code. To simulate or synthesize, copy the contents into a `.vhd` file inside a new Vivado or ModelSim project.

---

## How to Run

### Simulation (ModelSim)
1. Create a new project in ModelSim
2. Copy the contents of `machine d'etat structurelle te5dem.txt` into a new `.vhd` file
3. Compile and run the simulation
4. Add signals to the waveform viewer to inspect fetch/decode/execute cycles

### Synthesis (Xilinx Vivado)
1. Create a new RTL project in Vivado
2. Add the VHDL source files
3. Set the top-level entity to the microprocessor FSM
4. Run synthesis → implementation → generate bitstream
5. Program the Xilinx FPGA board

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
[chehinemelki033@gmail.com](mailto:chehinemelki033@gmail.com)
