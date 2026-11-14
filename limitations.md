# Protocol Emulator Architecture: Known Limitations, Constraints & Resolutions

While the 6-Core Accumulator ASIC is highly flexible and robust, it was originally designed under severe area constraints for the Sky130 130nm PDK (Tiny Tapeout) and subsequently updated for **IHP 130nm CMOS5L (`ihp-sg13cmos5l`)** with 6 independent cores, 8-bit bidirectional IO, dynamic RAM instruction memory, and real-time Two-Wire Debugging (`dvitantri_shodhana`). This document tracks the fundamental hardware/software compromises, architectural resolutions, and specific protocol constraints across all competition protocols: **UART, SPI, I2C, 10BASE-T Ethernet, and USB 1.1**.

---

## 1. Global Hardware & Architecture Constraints

### 1.1 Instruction Execution Overhead (Overcome via Multi-Core Pipelining)
Because this is a bare-metal, accumulator-based CPU without hardware barrel shifters or complex ALU instructions, single-core execution of complex protocols suffers from high instruction overhead (e.g., bit shifting requires multiple `SHL` instructions).
* **Limitation:** A monolithic single-core UART RX routine required ~39 clock cycles just to sample, shift, and store a single bit.
* **Resolution:** Overcome by redesigning firmware into a multi-core split-stream pipeline. Dedicated sampling cores (e.g., CPU 0) sample pins at line rate and forward raw bits via shared memory (`SHARED_0` .. `SHARED_5`) to shifting/framing cores (CPU 1), drastically reducing per-core cycle overhead and raising physical throughput. With 6 cores available, high-speed protocols can dedicate separate cores for RX sampling, deserialization, TX serialization, line driving, and real-time framing/parity inspection simultaneously.

### 1.2 No Hardware Interrupts
The CPUs do not possess hardware interrupt request (IRQ) capabilities or stack pointers.
* **Limitation:** A CPU cannot pause execution to service an asynchronous event.
* **Impact & Resolution:** Full-duplex protocols cannot run on a single core. The architecture allocates dedicated independent cores (e.g., CPU 0/1 for RX polling and CPU 2/3 for TX).

### 1.3 Instruction Memory Constraints & Dynamic RAM Transition
* **Limitation:** In raw D-Flip-Flop (DFF) synthesized memory, each CPU is strictly capped at **128 nibbles (64 Bytes)** of Instruction Memory.
* **Resolution:** The ASIC has transitioned from static hardcoded ROM to **dynamic on-chip instruction RAM loaded over high-speed SPI**. Protocols do not need to fit simultaneously in silicon: the host MCU (RP2040) dynamically hot-swaps firmware routines into RAM on demand across Cores 0 through 5.

### 1.4 Overrun Error Detection (Overcome via STATUS_FLAGS Register Bit 6)
The ASIC utilizes 8-byte hardware FIFOs to buffer data between the SPI Host and the internal CPUs.
* **Original Limitation:** If the external host did not poll the SPI bus quickly enough to drain the `TX_FIFO`, the hardware asserted `tx_full` and dropped overflow writes silently without explicitly alerting the executing core.
* **Resolution:** An `overrun_flag` has been integrated directly into the `STATUS_FLAGS` register (Bit 6 at address `0x8`). When a CPU attempts to write to `TX_FIFO` while `tx_full` is asserted, bit 6 of `STATUS_FLAGS` latches HIGH (`STATUS_FLAGS = {1'b0, overrun_flag, 4'b0, flag_carry, flag_zero}`). Reading `STATUS_FLAGS` automatically clears the latched overrun bit, giving firmware complete visibility into FIFO buffer overruns without polling shared registers.

### 1.5 Direct Memory Addressing (No Pointers or Stack)
* **Limitation:** The ISA only supports direct addressing (`LOAD addr`, `STORE addr`). There is no indirect pointer indexing (e.g., `LOAD [R2]`) or hardware stack.
* **Impact:** Firmware state machines operate on fixed memory-mapped register locations (`0x0` through `0xF`) without dynamic allocation or recursive calls.

### 1.6 Single-Bit Shift ALU
* **Limitation:** The ALU supports 1-bit shifts (`SHL`, `SHR`) without a multi-bit barrel shifter or multiplier.
* **Resolution:** Multi-bit shifts are handled via multi-core offloading, where data processing is parallelized across downstream cores while the front-end core stays locked onto pin timing.

### 1.7 Shared Physical Pin Interface & Bus Discipline
* **Limitation:** All six CPUs share the `uio_out[7:0]` pins, which are logically OR-ed in hardware with direction masking.
* **Impact & Resolution:** Firmware enforces strict pin assignment discipline so cores do not drive the same pin simultaneously:
  - Pin assignments are partitioned per protocol (e.g., Core 0 on Pin 0, Core 1 on Pin 1).
  - Open-drain protocols (I2C) toggle `pin_dir` with pin outputs set to 0.

### 1.8 Register Mapping: Shared Pipeline Registers (0x9 to 0xE)
* **Architecture:** Each CPU has private `ACC`, `B`, `R2`, and `R3` registers. Addresses `0x9` through `0xE` are memory-mapped to 6 inter-core shared pipeline registers (`SHARED_0` .. `SHARED_5`) with automatic hardware stall synchronization. Reading an empty shared register stalls the consumer core until the producer writes new data.

---

## 2. Competition Protocol Specific Limitations & Resolutions

### 2.1 UART (Universal Asynchronous Receiver-Transmitter)
* **Maximum Baud Rate:** The maximum baud rate is bounded by CPU 1's tightest polling loop (~15 cycles). At 50 MHz, this allows up to **~3.33 Mbps** verified baud rate.
* **Core Allocation for Parity & Full-Duplex:**
  - Supporting Full-Duplex UART with Parity (`8E1`) consumes all 4 cores:
    - **CPU 0:** RX Center-Sampler & Edge Detector
    - **CPU 1:** RX Bit Shifter & Deserializer
    - **CPU 2:** TX Serializer & Line Driver
    - **CPU 3:** Real-time Parity Watchdog on the RX pin
* **Clock Drift Tolerance:** Software center-sampling handles up to $\pm 4.5\%$ baud rate clock drift between sender and receiver before bit sampling errors occur.

---

### 2.2 SPI (Serial Peripheral Interface)
* **Full-Duplex Master Mode Bit-Banging:**
  - True full-duplex SPI Mode 0 (CPOL=0, CPHA=0) is implemented and verified over 4 wires: Pin 0 (`MOSI`), Pin 1 (`MISO`), Pin 2 (`SCK`), and Pin 3 (`CS`) on `uio[3:0]`.
  - In each clock period, the core simultaneously shifts out the next MOSI bit on SCK falling edges and samples incoming MISO data on SCK rising edges (`test_2_1` and `test_2_3`), shifting received bits into an internal accumulator while streaming to the host `TX_FIFO`.
* **Speed Ceiling & Dual-Core Acceleration:**
  - In a single core, SCK toggling, MOSI bit-shifting, and MISO sampling require sequential instructions (`LOADIB`, `LOAD PIN_STATE`, `SHL`, `STORE PIN_OUT`), achieving ~1.25 Mbps to 2.5 Mbps at 50 MHz.
  - With the 6-core architecture, a dual-core pipelined master (Core 0 dedicated to SCK/CS generation and Core 1 handling simultaneous serialization/deserialization over `SHARED_0` and `SHARED_1`) doubles throughput up to 5.0 Mbps.

---

### 2.3 I2C (Inter-Integrated Circuit)
* **Single-Core Memory Limit:** Monolithic single-core I2C state machines (Start, Stop, ACK, Clock Stretching, TX, RX) exceed the 128-nibble limit.
* **Resolution via Pipelining & RAM Swapping:**
  - **Dual-Core Pipelining:** CPU 0 operates physical open-drain line switching (`PIN_DIR` toggling) and clock stretching timeouts; CPU 1 handles byte framing and Host FIFO streaming.
  - **Dynamic Swapping:** On-chip RAM allows swapping between `i2c_master.asm` (TX) and `i2c_master_rx.asm` (RX) on the fly over SPI.
  - **10-bit Addressing Support:** Supported via multi-byte framing firmware (`protocols/i2c/i2c_master_10bit.asm` and `i2c_slave_10bit.asm`) implementing the UM10204 10-bit sequence (`11110xx` header byte + lower address byte + payload) verified in `test_3_5_i2c_10bit`.
* **Multi-Master Arbitration Support:** Fully supported in software (`protocols/i2c/i2c_master_arb.asm` verified in `test_3_6_i2c_multi_master_arb`). Master monitors `PIN_STATE` while floating SDA High; if another master asserts `'0'`, it yields the bus immediately and reports an arbitration-lost code (`0xEE`).
* **High-Speed Mode (3.4 Mbps):** Not reachable due to ~15-cycle instruction latency; Standard Mode (100 kbps), Fast Mode (400 kbps), and Fast Mode Plus (1 Mbps) are supported.

---

### 2.4 10BASE-T Ethernet (IEEE 802.3)
* **Differential Driver Symmetry (Zero Cross-Skew):**
  - **CPU 0** drives **TX+ (Pin 0)** and **CPU 1** drives **TX- (Pin 1)**.
  - Both driver routines are cycle-matched (5 cycles for State 1, 5 cycles for State 2), ensuring that TX+ and TX- flip strictly synchronously without cross-line skew.
* **Full-Duplex Operation via 6-Core Parallel Pipeline:**
  - **TX Pipeline (4 Cores):** CPU 3 (Serializer) $\rightarrow$ CPU 2 (Manchester Encoder) $\rightarrow$ CPU 0 (TX+ Driver on `uio[0]`) / CPU 1 (TX- Driver on `uio[1]`).
  - **RX Pipeline (2 Cores):** CPU 4 (Manchester Edge Detector on `uio[2]`) $\rightarrow$ CPU 5 (Bit Deserializer & CRC Feeder).
  - With the 6-core architecture, true simultaneous Full-Duplex 10BASE-T Ethernet is supported without requiring dynamic firmware swapping.
* **Clock Jitter at 50 MHz vs. 40/60 MHz:**
  - At 50 MHz (20ns clock), the 50ns half-bit requires alternating 2-cycle (40ns) and 3-cycle (60ns) delays, causing $\pm 10\text{ns}$ deterministic jitter (within the $\pm 11\text{ns}$ IEEE 802.3 limit).
  - Running the core clock at **40 MHz** ($2 \times 25\text{ns} = 50\text{ns}$) or **60 MHz** ($3 \times 16.67\text{ns} = 50\text{ns}$) achieves exact integer-cycle timing with **0ns jitter**.
* **Hardware Universal CRC-32 Accelerator (`सार्वत्रिक_चक्रीय_पुनरावृत्ति`):**
  - Full hardware IEEE 802.3 Ethernet CRC-32 (polynomial `0x04C11DB7`, Seed `0xFFFFFFFF`, XOR Out `0xFFFFFFFF`, RefIn=1, RefOut=1) is offloaded to the on-chip Galois LFSR engine at register address `0xD` (`CRC_DATA`) and `0xE` (`CRC_CTRL`).
  - Cores process 1 byte per clock cycle with zero CPU memory or instruction overhead; completed 4-byte CRC-32 remainders are read slice-by-slice via `CRC_CTRL`.
* **NLP Link Pulses:**
  - Normal Link Pulses (NLP) every 16ms are generated via host SPI triggers during idle periods.

---

### 2.5 USB 1.1 Low-Speed (1.5 Mbps)
* **Multi-Core Pipelined TX Topology:**
  - At 50 MHz, 1.5 Mbps bit time is 33.33 clock cycles (rounded to 33 cycles, ~1% error, well inside the USB $\pm 1.5\%$ specification).
  - Low-Speed TX is distributed across 3 cores:
    - **CPU 3 (Serializer):** Reads bytes from `RX_FIFO` and serializes LSB-first into `SHARED_2`.
    - **CPU 2 (Bit Stuffer):** Evaluates consecutive 1s; if 6 consecutive 1s occur, autonomously inserts a stuffed `0` bit and pushes to `SHARED_1`.
    - **CPU 1 (NRZI & Pin Driver):** Reads `SHARED_1` and toggles physical J/K bus states on Pin 0 (`D+`) and Pin 1 (`D-`) using `TIMER_L` for exact 33-cycle boundaries.
    - **CPU 0:** Left idle / available for host handshake.
* **Autonomous End-of-Packet (EOP) Generation:**
  - Physical EOP generation is executed 100% autonomously by the on-chip multi-core pipeline. CPU 1 directly drives Single-Ended Zero (SE0, `D+`=0, `D-`=0) for 2 bit intervals (66 cycles) followed by J-state for 1 bit interval (33 cycles) using hardware timer delays (`TIMER_L`).
  - EOP triggering can be initiated autonomously by CPU 3 upon encountering an in-band delimiter token (`0xFE`) or reaching the end of a configured packet length counter, without requiring external host intervention mid-packet. Host-assisted signaling via shared registers remains supported as an alternative handshake.
* **SYNC Pattern Optimization:**
  - USB SYNC pattern `K J K J K J K K` corresponds to byte `0x80` sent LSB-first in NRZI. No dedicated hardware is required; the host simply prepends `0x80` to the packet payload.
* **Full-Speed (12 Mbps) Limitation:**
  - USB Full-Speed (12 Mbps) requires a bit time of ~83.3ns (4.16 cycles @ 50 MHz), which cannot fit multi-cycle software bit-stuffing and NRZI state machines. Full-Speed is beyond software bit-banging limits; only Low-Speed (1.5 Mbps) is supported.
