# 6-Core Protocol Emulator ASIC: Master Feature Specification & Capability Matrix

Designed and developed by **[PivotVLSI](https://pivotvlsi.in/)** for the **Jane Street ASIC Hardware Challenge / Protocol Emulator Competition**, targeting the **IHP 130nm CMOS5L (`ihp-sg13cmos5l`)** process at **50 MHz**.

---

## 1. Executive Summary & Core Architectural Highlights

The **6-Core Protocol Emulator** replaces rigid fixed-function hardware macros with a parallel, software-defined multi-core architecture. It implements six custom 8-bit accumulator soft-cores (`संसाधक_०` through `संसाधक_५`), hardware-synchronized shared pipeline registers, dynamic instruction RAM hot-swapping, a universal 32-bit hardware CRC engine, and real-time serial debugging.

### Key Hardware Specifications:
- **Core Processing Units:** 6 independent 8-bit accumulator cores operating at 50 MHz.
- **Instruction Memory:** 128 nibbles (64 Bytes) of dynamic on-chip RAM per core, hot-swappable at runtime over a high-speed SPI configuration bus.
- **Inter-Core Synchronization:** 6 shared pipeline registers (`SHARED_0` .. `SHARED_5`, addresses `0x9` .. `0xE`) featuring hardware auto-stalling for zero-latency inter-core communication.
- **Bidirectional Protocol Bus:** 8 bidirectional user I/O pins (`uio[7:0]`) accessible by all 6 cores with non-contention direction-masked OR multiplexing.
- **Hardware Acceleration:**
  - **Universal CRC Accelerator (`सार्वत्रिक_चक्रीय_पुनरावृत्ति`):** Supports arbitrary polynomials from CRC-5 to CRC-32 (Galois parallel LFSR, 1 byte/cycle throughput, zero CPU stalls).
  - **Hardware Timers:** 16-bit countdown timers (`TIMER_L` at `0x7`, `TIMER_H` at `0x8`) with hardware-stalled exact cycle precision.
  - **Asynchronous FIFOs:** 8-byte RX and TX FIFOs per core with live status monitoring on physical pins (`uo_out[6:1]`) and overrun detection flags (`STATUS_FLAGS[6]`).
- **Real-Time Debug Tap (`द्वितन्त्री शोधन` / Two-Wire Debug):** Synchronous serial interface (`ui_in[3]`, `ui_in[2]`, `uo_out[7]`) for independent core halting, single-stepping, and reading of execution state (ACC, B, FLAGS, PC0, PC1, PC2, PIN_DIR, PIN_OUT).

---

## 2. Comprehensive Protocol Capability Matrix

| Protocol | Mode / Feature | Specification / Speed | Core Allocation & Pipeline Topology | Verification Status |
| :--- | :--- | :--- | :--- | :--- |
| **UART** | Basic TX | 300 baud to 3.125 Mbps | Single-Core (Core 0) | **PASS** (`test_1_1`) |
| **UART** | Dynamic Baud Rate | Configurable via SPI | Single-Core with variable timer reload | **PASS** (`test_1_2`) |
| **UART** | Continuous Streaming TX | Up to 3.125 Mbps | Single-Core with host FIFO flow control | **PASS** (`test_1_3`) |
| **UART** | Noise-Resilient Center-Sampling RX | Up to 1.25 Mbps | Dual-Core: Core 0 (Physical Pin Sampler) $\rightarrow$ Core 1 (Deserializer) | **PASS** (`test_1_4`) |
| **UART** | Framing Error Detection | Stop bit validation | Dual-Core (Flags framing violation to host) | **PASS** (`test_1_5`) |
| **UART** | Full-Duplex Simultaneous TX/RX | Up to 1.25 Mbps | 3 Cores: Core 0 (TX) + Core 1/2 (RX Pipeline) | **PASS** (`test_1_6`) |
| **UART** | Real-Time Parity Watchdog (`8E1`) | Up to 1.25 Mbps | 3 Cores: Core 0 (RX) $\rightarrow$ Core 1 (Framer) + Core 2 (Parity Checker) | **PASS** (`test_1_7`) |
| **UART** | Clock Drift & Jitter Tolerance | $\pm 5\%$ frequency offset | Dual-Core 16x oversampling filter | **PASS** (`test_1_8`) |
| **SPI** | Mode 0 (CPOL=0, CPHA=0) Full-Duplex Master | 1.25 Mbps – 2.5 Mbps | Single-Core concurrent MOSI shift-out & MISO sample-in over 4 wires (`uio[3:0]`) | **PASS** (`test_2_1`) |
| **SPI** | Dynamic Clock Rate Scaling | Configurable via timer | Single-Core timer-based edge scheduling (`TIMER_L`) | **PASS** (`test_2_2`) |
| **SPI** | Full-Duplex Streaming Data Transfer | Simultaneous TX/RX | Single-Core concurrent Host `RX_FIFO` pop & `TX_FIFO` push per frame | **PASS** (`test_2_3`) |
| **SPI** | Dual-Core Pipelined SPI Master | Up to 5.0 Mbps | Dual-Core: Core 0 (Clock & Pin Driver) $\leftrightarrow$ Core 1 (Serializer/Deserializer) | Architecture Ready |
| **I2C** | 7-Bit Master TX (Write Byte) | Standard (100k), Fast (400k), Fast+ (1M) | Dual-Core: Core 0 (Open-drain pin driver) $\rightarrow$ Core 1 (Framing) | **PASS** (`test_3_1`) |
| **I2C** | 7-Bit Master RX (Read Byte) | Standard, Fast, Fast+ | Dual-Core with ACK/NACK generation | **PASS** (`test_3_2`) |
| **I2C** | 7-Bit Slave RX (Device Mode) | Standard, Fast, Fast+ | Dual-Core with address matching | **PASS** (`test_3_3`) |
| **I2C** | 7-Bit Slave TX with Clock Stretching | Standard, Fast, Fast+ | Dual-Core holding SCL low via open-drain `PIN_DIR` | **PASS** (`test_3_4`) |
| **I2C** | 10-Bit Addressing Support | UM10204 10-bit sequence | Dual-Core: `11110xx` header + lower byte addressing | **PASS** (`test_3_5`) |
| **I2C** | Multi-Master Arbitration | Bus contention back-off | Master monitors SDA and yields immediately if lost (`0xEE`) | **PASS** (`test_3_6`) |
| **USB 1.1** | Low-Speed TX (1.5 Mbps) | 1.5 Mbps ($\pm 1\%$ timing) | 3 Cores: Core 3 (Serializer) $\rightarrow$ Core 2 (Stuffer) $\rightarrow$ Core 1 (NRZI/Driver) | **PASS** (`test_5_1`) |
| **USB 1.1** | Hardware Bit-Stuffing | Autonomous insertion | Core 2 inserts stuffed '0' after six consecutive '1's | **PASS** (`test_5_1`) |
| **USB 1.1** | Autonomous EOP Generation | 2-bit SE0 + 1-bit J-state | Core 1 drives SE0 for 66 cycles and J-state for 33 cycles | **PASS** (`test_5_1`) |
| **USB 1.1** | Low-Speed RX (1.5 Mbps) | 1.5 Mbps (33-cycle center sampling) | 3 Cores: Core 4 (Pin Sampler) $\rightarrow$ Core 5 (NRZI/Unstuffer) $\rightarrow$ Core 0 (Deserializer/CRC) | **PASS** (`test_5_2`) |
| **USB 1.1** | Bit Unstuffing & EOP Detection | Automatic token extraction | Core 5 drops stuffed '0's and extracts SE0 token to forward to Core 0 | **PASS** (`test_5_2`) |
| **10BASE-T** | Differential Transmit (TX) | 10 Mbps ($\pm 10\text{ns}$ jitter) | 4 Cores: Core 3 (Serializer) $\rightarrow$ Core 2 (Encoder) $\rightarrow$ Core 0/1 (Drivers) | **PASS** (`test_4_2`) |
| **10BASE-T** | Zero Cross-Skew Differential Pair | Cycle-matched drivers | Core 0 (`TX+` on `uio[0]`) & Core 1 (`TX-` on `uio[1]`) flip in exact sync | **PASS** (`test_4_2`) |
| **10BASE-T** | Manchester Edge-Sampling RX | 10 Mbps line rate | 2 Cores: Core 4 (Edge Detector) $\rightarrow$ Core 5 (Deserializer & CRC) | **PASS** (`test_4_3`) |
| **10BASE-T** | Simultaneous Full-Duplex | 10 Mbps concurrent TX/RX | 6 Cores: 4 Cores TX + 2 Cores RX operating simultaneously | **PASS** (`test_4_3`) |
| **CRC Engine** | Universal Arbitrary CRC Generator | 50 MB/s (1 byte / cycle) | Hardware Galois LFSR supporting CRC-5 to CRC-32 (IEEE 802.3, etc.) | **PASS** (`test_4_3`) |

---

## 3. Hardware Subsystems & Microarchitecture Details

### 3.1 Universal CRC Accelerator (`सार्वत्रिक_चक्रीय_पुनरावृत्ति`)
The on-chip CRC accelerator is a parameterizable, parallel Galois LFSR capable of calculating CRC remainders for any standard or proprietary protocol in a single clock cycle per byte:
- **Maximum Width:** 32 bits (`अधिकतम_विस्तार = 32`).
- **Runtime Host Configuration via SPI:**
  - Divisor Polynomial (`भाजक_बहुपद_पञ्जिका`): 32-bit register (`0x61` .. `0x64`).
  - Initial Seed (`प्रारम्भिक_बीज_पञ्जिका`): 32-bit register (`0x65` .. `0x68`).
  - Output Inversion Mask (`उत्क्रम_आवरण_पञ्जिका`): 32-bit register (`0x69` .. `0x6C`).
  - Reflection Flags (`प्रतिबिम्ब_निवेश_ध्वज`, `प्रतिबिम्ब_निर्गम_ध्वज`): Bit-reversal controls (`0x6D`).
  - Reseed Command: Resets engine state to initial seed (`0x6E`).
- **Core Access Interface:**
  - `STORE CRC_DATA` (`0xD`): Feeds an 8-bit byte into the engine (updates in 1 cycle).
  - `STORE CRC_CTRL` (`0xE`): Selects the byte slice (`0`=Bits 7:0, `1`=Bits 15:8, `2`=Bits 23:16, `3`=Bits 31:24).
  - `LOAD CRC_DATA` (`0xD`): Reads the selected remainder slice.

### 3.2 Two-Wire Real-Time Debugger (`द्वितन्त्री शोधन`)
Enables non-intrusive silicon debugging and single-step verification without halting unselected cores:
- **Physical Pins:** Synchronous serial protocol over `ui_in[3]` (`DBG_SCLK`), `ui_in[2]` (`DBG_DIN`), and `uo_out[7]` (`DBG_DOUT`).
- **Target Selection:** Individual core selection (`Core 0` through `Core 5`).
- **Halt & Resume Controls:** Independent halt command (`cmd = 0x01`), step command (`cmd = 0x02`), and resume command (`cmd = 0x00`).
- **Live Register Readout:** Shifts out complete 8-bit internal states:
  - Math Accumulator (`ACC`)
  - Secondary Math Register (`B`)
  - Status Register (`FLAGS`)
  - Split-Stream Program Counters (`PC0`, `PC1`, `PC2`)
  - General Registers (`R2`, `R3`)
  - Pin Output & Direction States (`PIN_OUT`, `PIN_DIR`)

### 3.3 Pin Direction Masking & Bus Multiplexing
- All 8 bidirectional protocol pins (`uio[7:0]`) are shared across all 6 cores.
- **Direction Control:** Output enable is combined via bitwise-OR: `uio_oe = cpu0_pin_dir | cpu1_pin_dir | cpu2_pin_dir | cpu3_pin_dir | cpu4_pin_dir | cpu5_pin_dir`.
- **Contention Prevention:** Pin outputs are masked with their respective direction registers (`cpuX_safe_out = cpuX_pin_dir & cpuX_pin_out`) before being logically OR-ed onto the physical pads, preventing physical driver contention during protocol switching.

---

## 4. Documentation Map
For full technical details, consult the following architectural documents:
- **[Architecture Overview](arch.md):** Block diagrams, clock domains, and inter-core memory layouts.
- **[ISA Specification](isa_spec.md):** The 4-bit nibble instruction set, addressing modes, and opcode tables.
- **[Pin Mapping](pin_mapping.md):** User I/O pin assignments under the Tiny Tapeout ASIC framework.
- **[Known Limitations & Resolutions](limitations.md):** Comprehensive analysis of software-defined bottlenecks and hardware workarounds.
- **[Verification Guide](verif_readme.md):** Regression testbench suite and execution instructions.
