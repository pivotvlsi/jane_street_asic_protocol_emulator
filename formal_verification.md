# Formal Verification Specification & Verification Architecture

This document details the complete verification methodology for the **6-Core Software-Defined Protocol Emulator ASIC**, covering **Formal Verification (SymbiYosys / SVA)**, **Regression Verification (Cocotb)**, and **Multi-Protocol System Testbenches**.

---

## 1. Formal Verification Architecture

Formal verification proves that under **all possible input sequences and timings**, the hardware invariants and safety properties can never be violated.

### 1.1 Toolflow & Execution
* **Front-End & Preprocessor:** Yosys Formal (`read -formal -sv`)
* **Formal Harness Driver:** SymbiYosys (`sby`) configuration file: [`formal/protocol_emulator.sby`](file:///c:/Users/rnish/vscode/Pasupathi/pivotvlsi/jane_street_workshop/formal/protocol_emulator.sby)
* **Solver Engine:** `smtbmc` (Z3 / Boolector SMT solvers)
* **Execution Modes:**
  * **Bounded Model Checking (BMC):** Unrolls the design state graph up to depth $K = 32$ clock cycles to catch any reachable safety property violation from reset.
  * **Mathematical Induction (`prove`):** Proves that an invariant holds indefinitely for all $t \to \infty$ by proving the base step and inductive step across states.

### 1.2 Formally Proven Hardware Modules

#### A. Asynchronous/Synchronous FIFO Buffer (`fifo.v`)
Targeted in [`formal/formal_protocol_emulator.sv`](file:///c:/Users/rnish/vscode/Pasupathi/pivotvlsi/jane_street_workshop/formal/formal_protocol_emulator.sv):
* **Mutual Exclusivity Invariant:**
  $$\square \; \neg (\text{empty} \land \text{full})$$
  Formal proof guarantees that FIFO `empty` and `full` status flags can never be asserted simultaneously for any non-zero buffer depth.
* **Count & Pointer Invariance:**
  $$\square \; (\text{count} == 0 \iff \text{empty})$$
  $$\square \; (\text{count} == \text{DEPTH} \iff \text{full})$$
* **No-Underflow & No-Overflow Protection:**
  Reading from an empty FIFO or writing to a full FIFO maintains data consistency and pointer sanity without memory wraparound corruption.

#### B. Two-Wire Debugger Unit (`dvitantri_shodhana.v`)
* **Core Halt & Step Invariant:**
  Asserts that halting a targeted core `X` via serial debug command drives `dbg_halt[X] = 1` deterministically without side effects or clock jitter across other cores $Y \ne X$.
* **Debug Bus Multiplexer Isolation:**
  Proves that inspecting internal registers (`ACC`, `AUX`, `FLAGS`, `PC`, `GPIO_DIR`, `GPIO_OUT`) of core $X$ never leaks or corrupts state in any active parallel core.

#### C. GPIO & Shared Resource Ownership (`formal/competitor_reference/`)
* **Pin Contention Mutual Exclusion:**
  $$\square \; \neg (\text{Core}_A\text{\_Driving\_High} \land \text{Core}_B\text{\_Driving\_Low})$$
  Bidirectional `uio[3:0]` open-drain vs. push-pull configurations prevent electrical cross-conduction or short-circuit contention when multiple cores arbitrate for the shared I/O bus.
* **Shared CRC Accelerator Arbitration:**
  Proves that hardware CRC registers and calculation states remain deterministic when sequential cores execute polynomial division.

---

## 2. Verification Hierarchy Matrix

| Verification Tier | Engine / Framework | Target Coverage | Files / Path |
| :--- | :--- | :--- | :--- |
| **Formal Invariants (SVA)** | SymbiYosys (`smtbmc`) | Mathematical boundary proofs (FIFO underflow/overflow, debug isolation, state unreachable states) | `formal/protocol_emulator.sby`<br>`formal/formal_protocol_emulator.sv` |
| **ASIC Integration (Cocotb)** | Python 3 + Icarus Verilog (`iverilog`) | 6-core reset, Two-Wire Debugger live halting/resuming, SPI slave register streaming, CRC accelerator parameter preloading | `test/test_cocotb_protocols.py` |
| **Protocol Simulation Suite** | Icarus Verilog + Perl Test Runner | 20 protocol testbenches (UART, SPI, I2C, Ethernet, USB) covering jitter, noise, clock drift, multi-core pipelining | `tests/test_*.v`<br>`run_tests.pl` |

---

## 3. Protocol Test Suite Coverage (20 Verilog Testbenches)

Detailed test scenarios automated via `perl run_tests.pl`:

### 3.1 UART Protocol (8 Testbenches)
1. **`test_1_1_uart_tx_basic`**: Baseline 8N1 transmission verifying accurate start bit, 8 data bits (LSB-first), and stop bit pulse widths.
2. **`test_1_2_uart_tx_dynamic_baud`**: Runtime baud rate adaptation via hardware timer `TIMER_L`.
3. **`test_1_3_uart_tx_streaming`**: Continuous back-to-back FIFO streaming without inter-byte underflow or stop-bit truncation.
4. **`test_1_4_uart_rx_noise`**: Line glitch filtering and 3-point center-sampling noise rejection.
5. **`test_1_5_uart_rx_framing`**: Stop-bit missing violations and framing error flag assertion.
6. **`test_1_6_uart_rx_parity`**: Even-parity (`8E1`) calculation and error bit reporting.
7. **`test_1_7_uart_dual_core_rx`**: Dual-core pipelining: Core 0 performs edge detection/baud timing; Core 1 decodes bytes and computes parity.
8. **`test_1_8_uart_rx_clock_drift`**: Reception robustness under $\pm 4.5\%$ baud rate clock frequency mismatch.

### 3.2 SPI Protocol (1 Testbench)
9. **`test_2_1_spi_master`**: Full-duplex Mode 0 ($CPOL=0, CPHA=0$) bit-banged SPI master with external slave loopback.

### 3.3 I2C Protocol (6 Testbenches)
10. **`test_3_1_i2c_master`**: Master 7-bit addressing, payload transmission, and ACK/NACK validation.
11. **`test_3_2_i2c_slave`**: Slave address detection, byte capture, and open-drain ACK generation.
12. **`test_3_3_i2c_loopback`**: Master-to-slave internal open-drain loopback with pull-up emulation.
13. **`test_3_4_i2c_loopback_rx`**: Slave-to-master transmission with dynamic SCL clock-stretching support.
14. **`test_3_5_i2c_10bit`**: Multi-core 10-bit addressing loopback (`11110xx` header + address byte + payload).
15. **`test_3_6_i2c_multi_master_arb`**: Multi-master bus arbitration loss detection and collision-free back-off release.

### 3.4 Ethernet 10BASE-T (3 Testbenches)
16. **`test_4_1_ethernet_tx`**: Zero-skew differential Manchester encoding with preamble and SFD (`0xD5`).
17. **`test_4_2_ethernet_rx`**: Manchester mid-bit transition sampling and dual-core edge decoding.
18. **`test_4_3_ethernet_full_duplex`**: Simultaneous full-duplex transmission and reception across separate core clusters.

### 3.5 USB 1.1 Low-Speed (2 Testbenches)
19. **`test_5_1_usb_tx`**: 1.5 Mbps 3-core pipelined NRZI transmission with automatic bit-stuffing (after 6 consecutive 1s) and Single-Ended Zero (SE0) End-of-Packet (EOP).
20. **`test_5_2_usb_rx`**: 3-core RX pipeline (line sampler $\rightarrow$ NRZI unstuffer $\rightarrow$ deserializer/CRC) with center-sampling and EOP SE0 detection.

### 3.6 Debug Controller (1 Testbench)
21. **`test_debug_controller`**: Two-Wire Debugger halt, single-step PC, resume, and register inspection across all 6 cores.

---

## 4. How to Execute Verifications

### Running Formal Verification
```bash
cd formal
sby -f protocol_emulator.sby
```

### Running Cocotb Regressions
```bash
pytest test/test_cocotb_protocols.py
```

### Running All Protocol Testbenches
```bash
perl run_tests.pl
```
*(Or specify individual tests, e.g., `perl run_tests.pl 1_7 usb i2c_10bit`)*
