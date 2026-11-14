# Protocol Emulator ISA Specification (Final - Load/Store Architecture)

To achieve the absolute highest code density and the simplest possible hardware decoder, this ISA uses a **Load/Store Accumulator Architecture** built entirely on 1-nibble and 2-nibble instructions.

This allows the FSM to use 4-bit addresses (giving access to 16 memory-mapped registers). The **Program Counter (PC) is 7 bits**, meaning it can address up to 128 individual nibbles (64 Bytes total) of instruction memory per FSM.

## Instruction Decoder Logic
The hardware decodes instructions based on the 4-bit opcode:
* `0xxx` (Opcodes `0` to `7`): **1-Nibble Instruction** (4 bits total, 0 Operands).
* `1000` to `1100` (Except `1010`): **2-Nibble Instruction** (8 bits total, 1 Operand: 4-bit Address or Pin).
* `1101` to `1111` & `1010`: **3-Nibble Instruction** (12 bits total, 2 Operands for Jumps and LOADI).


## 1. Instruction Memory (Split-Stream Pipeline)

To achieve 1-clock-cycle execution, the Instruction ROM is split into 4 physical memory blocks per CPU. The CPU fetches from all of them simultaneously:
1. **OP RAM (128x4):** Contains only the 4-bit Opcode. Addressed by `pc_op` (7 bits).
2. **OP1 RAM (64x4):** Contains the 1st operand nibble (if needed). Addressed by `pc_op1` (6 bits).
3. **OP2 RAM (16x4):** Contains the 2nd operand nibble (if needed). Addressed by `pc_op2` (4 bits).
4. **JUMP TABLE (16x17):** Contains up to 16 absolute `{pc_op[6:0], pc_op1[5:0], pc_op2[3:0]}` target states used for branching.

When an instruction executes, the CPU automatically increments the required program counters. A 1-nibble instruction only increments `pc_op`. A 2-nibble instruction increments `pc_op` and `pc_op1`. A 3-nibble instruction increments all three.

---

## 2. Register & Memory Map (16 Address Space)
Every data register is exactly **8 bits (1 byte) wide**, which perfectly matches standard serial protocols like UART, SPI, and I2C. Addresses `0x0` through `0x3` are private execution registers, `0x4` to `0x8` access hardware peripherals, `0x9` to `0xC` access hardware-synchronized shared registers across all 6 CPUs, `0xD` and `0xE` access the **Universal Arbitrary CRC Accelerator**, and `0xF` configures 8-bit bidirectional IO.

| Address (Hex) | Register Name | Access Type | Description |
| :--- | :--- | :--- | :--- |
| `0x0` | **ACC** | Read / Internal | Math Accumulator. Hardwired for ADD / SUB / AND / SHR / SHL / XOR. |
| `0x1` | **B** | Read / Write | Secondary Math Register (Operand for math). |
| `0x2` | **R2** | Read / Internal | General-purpose Scratch Register / Loop Counter. |
| `0x3` | **R3** | Read / Internal | General-purpose Scratch Register. |
| `0x4` | **TX_FIFO** | Write | Moving data here pushes it to the SPI host FIFO. **Stalls CPU if FIFO is full.** |
| `0x5` | **RX_FIFO** | Read | Moving data from here pops it from the SPI host FIFO. **Stalls CPU if FIFO is empty.** |
| `0x6` | **PIN_STATE** | Read | Reads the external physical pin voltages (`uio_in[7:0]`). |
| `0x7` | **TIMER_L** | Read / Write | Lower 8 bits of the hardware timer. **Stalls CPU on read until timer countdown reaches zero.** |
| `0x8` | **STATUS_FLAGS** | Read / Write | **Write:** Loads upper timer byte and starts countdown.<br>**Read:** ALU Status Flags:<br>• Bit 0: `flag_zero`<br>• Bit 1: `flag_carry`<br>• Bit 6: `overrun_flag` (TX FIFO overrun)<br>• Bits 7, 5:2: Reserved (`0`) |
| `0x9` | **SHARED_0** | Read / Write | Shared register across all 6 CPUs. **Stalls CPU on read if data is not valid.** |
| `0xA` | **SHARED_1** | Read / Write | Shared register across all 6 CPUs. **Stalls CPU on read if data is not valid.** |
| `0xB` | **SHARED_2** | Read / Write | Shared register across all 6 CPUs. **Stalls CPU on read if data is not valid.** |
| `0xC` | **SHARED_3** | Read / Write | Shared register across all 6 CPUs. **Stalls CPU on read if data is not valid.** |
| `0xD` | **CRC_DATA** | Read / Write | **Write:** Feeds 8 bits into Universal CRC Galois LFSR.<br>**Read:** Returns selected byte slice of current CRC remainder. |
| `0xE` | **CRC_CTRL** | Write | **Write:** CRC Control:<br>• Bits 1:0: Byte slice select (0..3) for reading CRC remainder at `0xD`<br>• Bit 2: Trigger software re-seed |
| `0xF` | **PIN_DIR** | Read / Write | **Write:** Sets 8-bit bidirectional pin direction (`pin_dir <= ACC[7:0]`, `1` = Output, `0` = Input).<br>**Read:** Returns current 8-bit pin direction `pin_dir[7:0]`. |

---

## 3. Universal Arbitrary CRC Hardware Accelerator (SPI Host Preload)

To offload polynomial division, the ASIC incorporates a dedicated 32-bit Galois LFSR hardware accelerator (`\सार्वत्रिक_चक्रीय_पुनरावृत्ति`). It supports **any polynomial** (e.g. CRC-5 USB Token, CRC-16 USB Data, CRC-32 Ethernet IEEE 802.3, or custom proprietary CRCs) preloaded by the host MCU (RP2040) over SPI:

### SPI Host Preload Protocol (`0x60` to `0x6E`):
* `0x60`: **CRC Width ($W$)** (1 to 32 bits)
* `0x61 .. 0x64`: **Divisor Polynomial ($P[31:0]$)** (Bytes 0 to 3)
* `0x65 .. 0x68`: **Initial Seed ($I[31:0]$)** (Bytes 0 to 3)
* `0x69 .. 0x6C`: **XOR Out Mask ($X[31:0]$)** (Bytes 0 to 3)
* `0x6D`: **Reflection Flags** (Bit 0: `RefIn`, Bit 1: `RefOut`)
* `0x6E`: **Re-seed Trigger** (Reloads initial seed into running accumulator)

Once preloaded, any core simply executes `STORE 0xD` to feed bytes on the fly, achieving single-cycle absorption at **400 Mbps**.

---

## Instruction Set Summary

| Opcode | Length | Instruction | Description |
| :--- | :--- | :--- | :--- |
| `0000` | 1 Nibble | **ADD** | `ACC = ACC + B` |
| `0001` | 1 Nibble | **SUB** | `ACC = ACC - B` |
| `0010` | 1 Nibble | **AND** | `ACC = ACC & B` (Bitwise AND) |
| `0011` | 1 Nibble | **XOR** | `ACC = ACC ^ B` (Bitwise XOR) |
| `0100` | 1 Nibble | **SHR** | Shifts `ACC` to the right by 1 bit. |
| `0101` | 1 Nibble | **SHL** | Shifts `ACC` to the left by 1 bit. |
| `0110` | 1 Nibble | **NOP** | Do absolutely nothing for 1 clock cycle. |
| `0111` | 3 Nibbles | **LOADIB** `imm8`| Loads an 8-bit constant directly into the `B` register. (`B = imm8`). Consumes 2 operand nibbles. |
| `1000` | 2 Nibbles | **SET0** `pin` | Actively drives the specified `pin` LOW (`0`). |
| `1001` | 2 Nibbles | **SET1** `pin` | Actively drives the specified `pin` HIGH (`1`). |
| `1010` | 3 Nibbles | **LOADI** `imm8`| Loads an 8-bit constant into `ACC`. (`ACC = imm8`). Consumes 2 operand nibbles. |
| `1011` | 2 Nibbles | **LOAD** `addr`| Loads data from `addr` into `ACC`. (`ACC = memory[addr]`) |
| `1100` | 2 Nibbles | **STORE** `addr`| Stores data from `ACC` into `addr`. (`memory[addr] = ACC`) |
| `1101` | 2 Nibbles | **JMP** `id` | Restores all three PCs from `JUMP_TABLE[id]` unconditionally. |
| `1110` | 2 Nibbles | **JMPNZ** `id`| Restores PCs from `JUMP_TABLE[id]` if Zero Flag == 0. |
| `1111` | 2 Nibbles | **JMPC** `id` | Restores PCs from `JUMP_TABLE[id]` if Carry Flag == 1. |
