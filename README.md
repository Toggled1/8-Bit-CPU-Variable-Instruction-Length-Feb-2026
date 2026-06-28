# Custom 8-bit CPU (Variable-Length Instruction Set)

## Project Overview

This is a custom 8-bit CPU I built in VHDL, along with a full toolchain (Python assembler + RAM initialization for simulation).

> **Note:** This project also includes a SystemVerilog port of the architecture, which utilizes **Icarus Verilog** for simulation.

I was introduced to RTL design in one of my courses last fall, and I got really interested in it, so I decided to start my own small project!

What it supports:
- 8-bit core with a 16-bit variable-length instruction format
- Synchronous RAM (read/write, FPGA-style behavior)
- Register-based datapath with ALU + flag logic
- Multi-cycle FSM (fetch/decode/execute)
- Custom Python assembler that generates machine code

---

## Architecture Overview

**Take a look!** This schematic shows the top-level system interconnect for the cpu! (some details are omited here for simplicity)

![top level system](images/8-Bit-CPU-Top-Level-System-Interconnect.png)

### Core Design

- 8-bit datapath CPU
- Variable-length instructions (1-byte and 2-byte formats)
- General-purpose register file (R0–R7)
- Special registers: PC, IR, IR1, Status Register (SR)
- ALU handles arithmetic, logic, and flag generation

---

### Memory System

- Synchronous RAM for both reads and writes (so it behaves like FPGA)
- RAM is initialized from the assembler output file at simulation start
- CPU executes directly from this preloaded memory image

---

## Datapath Design

The datapath connects all the main CPU components:

- Instruction Register (IR)
- Secondary Instruction Register (IR1)
- Program Counter (PC)
- Status Register (SR)
- General Purpose Registers (R0–R7)

Key behaviour:
- PC increment happens in the datapath
- PC can also be overridden by control logic for branches/jumps
- A write-back mux selects between ALU output and memory data

---

## Control Unit (CPU FSM) - "CPU Frame"

The CPU runs on a multi-stage FSM that accounts for synchronous RAM latency. It utilizes Look-Ahead Decoding. Compared to earlier revisions to this FSM, the need for dedicated decode cycles has been eliminated by making opcodes and register selections based directly from the RAM wires during buffer states.

**Take a look!** This schematic shows control logic in a finite state machine ;)

![control fsm](images/FSM_state_transitions.png)

### Single-byte instruction cycle:
FETCH0 → FETCH0_BUF → EXECUTE  

### Double-byte instruction cycle:
FETCH0 → FETCH0_BUF → FETCH1 → FETCH1_BUF → [LOADOPS] → EXECUTE  

**Note:** This optimized FSM achieves a variable execution rate of 3 to 6 cycles. The Buffer states perform allow the synchronous RAM output to stabilize while also decoding the incoming instruction bits!

The control unit (CPU frame) handles:
- **Instruction Sequencing:** Routes the FSM based on instruction length (8-bit vs 16-bit).
- **Memory Timing Handling:** Manages the `LOADOPS` and `BUF` states such that the synchronous RAM bus is stable before latching data.
- **Execution Flow Control:** Controls PC increments and write-back signals for the datapath and status registers.

---

## ALU Design

The ALU supports basic arithmetic and logic operations, and also generates standard CPU flags:

- Zero (Z)
- Carry (C)
- Negative (N)
- Overflow (V)

It also has a passthrough mode for operations like MOVE where no real ALU operation is needed.

------------------------------------
Instruction Set Architecture (ISA)
------------------------------------
NOTE: imm is applicable to 2-byte (double-length) instructions

### Instruction Format

#### Byte 0

| Bit | 7 | 6 | 5 | 4 | 3   | 2 | 1 | 0 |
|-----|---|---|---|---|-----|---|---|---|
|     | X | X | X | X | imm | A | A | A |

- `XXXX` = Opcode  
- `imm`  = Immediate flag  
- `AAA`  = Destination register select (R[A])

---

#### Byte 1 (imm = 0)

| Bit | 7 | 6 | 5 | 4 | 3 | 2 | 1 | 0 |
|-----|---|---|---|---|---|---|---|---|
|     | B | B | B | – | – | – | – | – |

- `BBB` = Source register select (R[B])  
- `src` = R[B]

---

#### Byte 1 (imm = 1)

| Bit | 7 | 6 | 5 | 4 | 3 | 2 | 1 | 0 |
|-----|---|---|---|---|---|---|---|---|
|     | Y | Y | Y | Y | Y | Y | Y | Y |

- `YYYYYYYY` = 8-bit address  
- `src` = MEM[addr]




| Opcode | OP     | Length  | Scheme |
|:------:|--------|---------|--------|
| 0000   | CLEAR  | 1 byte  | `R[A] ← 0` |
| 0001   | LOAD   | 2 bytes | `R[A] ← MEM[addr]` (imm=1) |
| 0010   | STORE  | 2 bytes | `MEM[addr] ← R[A]` (imm=1) |
| 0011   | MOVE   | 2 bytes | `R[A] ← R[B]` (imm=0) |
| 0100   | BZ     | 2 bytes | `if ZF=1 then PC ← addr` (imm=1) |
| 0101   | BN     | 2 bytes | `if NF=1 then PC ← addr` (imm=1) |
| 0110   | BRANCH | 2 bytes | `PC ← addr` (imm=1) |
| 0111   | OR     | 2 bytes | `R[A] ← R[A] OR src` |
| 1000   | XOR    | 2 bytes | `R[A] ← R[A] XOR src` |
| 1001   | AND    | 2 bytes | `R[A] ← R[A] AND src` |
| 1010   | NOT    | 1 byte  | `R[A] ← NOT R[A]` |
| 1011   | ADD    | 2 bytes | `R[A] ← R[A] + src` |
| 1100   | SUB    | 2 bytes | `R[A] ← R[A] - src` |
| 1101   | INC    | 1 byte  | `R[A] ← R[A] + 1` |
| 1110   | DEC    | 1 byte  | `R[A] ← R[A] - 1` |
| 1111   | NOP    | 1 byte  | `no operation` |




## Toolchain Overview

This project uses a simple custom toolchain to convert assembly code into CPU-executable machine code in simulation.<br><br>

Assembly → Custom Assembler → Machine Code → RAM Initialization → CPU Execution (GHDL)<br><br>

---

## Custom Assembler

This project includes a custom-built assembler for the CPU architecture.<br>
It translates assembly code into machine code and generates a memory initialization file used by the simulator.<br><br>

### Features

<b>Section-based program layout</b><br>
- <code>.data</code>: initialized variables stored in memory<br>
- <code>.bss</code>: reserved uninitialized memory space<br>
- <code>.text</code>: executable instructions<br><br>

**Note:** writes in order: .text → .data → .bss

<b>Comments</b><br>
- Anything after <code>#</code> is ignored by the assembler<br><br>

<b>Labels</b><br>
- Supports symbolic labels (e.g. <code>multiply_loop:</code>)<br>
- Labels are resolved to instruction addresses during assembly<br>
- Enables branching with <code>BRANCH</code>, <code>BN</code>, etc.<br><br>



---

## Verification & Testing Framework

To ensure the CPU executes programs correctly and also to troubleshoot MANY MANY problems, I used a hybrid verification approach using both waveform analysis in GTK Wave and automated memory checking.

- **Waveform Analysis:** Using **GHDL** and **GTKWave**, the simulated waveforms can be visually debugged during execution.

> **Note:** The Systemverilog port uses **Icarus Verilog** for sim and **VaporView** to view waveform within VS code.


- **Automated RAM Dumping:** I coded a testbench (`tb/cpu_tb.vhd`) to dump the final contents of the synchronous RAM to a text file at the end of the simulation.

- **Python RAM Verification Script:** I designed a script (`verification_scripts/ram_dump_verify.py`) to parse this output and cross-references it against the expected values read from another file. It automatically asserts whether the program executed successfully. If there is a mismatch in RAM content, it asserts the specific address and values that were incorrect.


---

## Example Program (Repeated Addition Multiplication)

<pre>

.data
num1 0x07          # Multiplicand: First number to multiply [7]
num2 0x05          # Multiplier: Second number to multiply [5]
prod 0x00          # Variable to store the final product

.text
######## Initialization
CLEAR R2           # R2 will hold our running product, initialize to 0
LOAD R0, num1      # Load the multiplicand into R0
LOAD R1, num2      # Load the multiplier into R1

######## Multiplication Loop
multiply_loop:
DEC R1             # Decrement the multiplier (count--)
BN end_loop        # If the result is negative (was 0 before DEC), exit loop
ADD R2, R0         # Add the multiplicand (R0) to the running product (R2)
BRANCH multiply_loop # Unconditional jump back up to repeat the loop

######## Program End
end_loop:
STORE R2, prod     # Store the final calculated product back into memory

END: BRANCH END    #No hault, so just loop!
</pre>

---

## Assembler Output (Machine Code)

<pre>
02
18
10
19
11
E1
58
0C
B2
00
68
05
2A
12
68
0E
07
05
00

</pre>

---

## RAM Integration

The RAM module was modified to load the assembler output file at simulation startup.<br><br>

Execution flow:<br>
Assembly → Assembler → Machine code file → RAM preload → CPU execution<br><br>

- Machine code is written to a file by the assembler<br>
- RAM reads values sequentially using <code>std.textio</code> and <code>ieee.std_logic_textio</code><br>
- CPU executes directly from initialized memory<br><br>

---

## Output Example

The program computes:

<pre>
7 × 5 = 35
</pre>

Result:<br>
- Stored in <code>Memory[0x12]</code><br>
- Value = 35 (decimal)<br>
- Accumulated in <code>R2</code><br><br>

---

## Waveform for Multiplication Program

<img src="images/multiplication_program_waveform.png">


------------------------------------
To run
------------------------------------

To run the full CPU simulation and verification pipeline, follow these steps in an Ubuntu terminal:

 **Bash commands:**
   ```bash
   chmod +x run_cpu_simulation.sh

   ./run_cpu_simulation.sh
   ```

> **To run systemverilog port:**
  ```bash
  iverilog -g2012 -o cpu_tb.out sv/*.sv tb/*.sv && vvp cpu_tb.out
  ```

This runs the Python assembler, then the VHDL simulation, opens GTK wave, then runs the verification Python program