# Verification Suite Guide

This repository contains a fully automated master verification suite designed to assemble all custom firmware routines, compile and simulate the Quad-Core ASIC using Icarus Verilog, and evaluate all protocol edge cases across 16 testbenches.

## Prerequisites
To run the master verification script, ensure you have the following installed in your system PATH:
* **Perl** (Used to run `run_tests.pl` and the `assembler.pl` compiler)
* **Icarus Verilog (`iverilog` & `vvp`)** (To compile and simulate the Verilog RTL)
* **GTKWave** (Optional: for viewing waveform `.vcd` dumps)

## How to Run the Tests
Execute the master Perl script from the root directory of the repository:

```bash
perl run_tests.pl
```

### Running Specific Tests
If you only want to run specific testcases, pass a filter string or test number as command-line arguments:
```bash
# Run only UART Parity and Dual-Core RX tests:
perl run_tests.pl 1_6 1_7

# Run only Ethernet tests:
perl run_tests.pl ethernet

# Run only USB tests:
perl run_tests.pl usb
```

### What the Script Does:
1. **Assembles Assembly Firmware:** Dynamically traverses the `protocols/` directory and compiles all `.asm` source files into opcode, operand, and jump table hex files (`*_op.hex`, `*_op1.hex`, `*_op2.hex`, `*_jmp.hex`) using `assembler.pl`.
2. **Discovers Testbenches:** Scans the `tests/` directory for testbenches (`test_*.v`).
3. **Simulates RTL:** Compiles the testbenches against the top-level design (`rtl/top.v` / `src/`) using `iverilog` and executes them via `vvp`.
4. **Verifies Hardware Outputs:** Inspects simulation outputs and verifies that byte payloads received and transmitted match expected protocol framing, timings, and FIFO status registers.
5. **Generates Waveforms:** Generates cycle-accurate `.vcd` files for detailed timing analysis in GTKWave.

## Viewing Waveforms
If you want to inspect the exact cycle-accurate timing of a protocol transmission:
```bash
gtkwave test_1_7_uart_dual_core.vcd
gtkwave uart_tx_basic.vcd
```

## Test Suite Coverage (20 Tests)
* **UART (8 Tests):**
  * `test_1_1_uart_tx_basic`: Standard 8N1 transmission.
  * `test_1_2_uart_tx_dynamic_baud`: On-the-fly baud rate reconfiguration via `TIMER_L`.
  * `test_1_3_uart_tx_streaming`: Back-to-back FIFO streaming without inter-byte underflow.
  * `test_1_4_uart_rx_noise`: Glitch filtering and center-sampling resilience.
  * `test_1_5_uart_rx_framing`: Stop-bit violation and framing error handling.
  * `test_1_6_uart_rx_parity`: Even-parity (`8E1`) calculation and error detection.
  * `test_1_7_uart_dual_core_rx`: Dual-core collaborative receiving and parity evaluation.
  * `test_1_8_uart_rx_clock_drift`: Verification under $\pm 4.5\%$ baud rate frequency deviation.
* **SPI (1 Test):**
  * `test_2_1_spi_master`: Mode 0 full-duplex SPI bit-banging master.
* **I2C (6 Tests):**
  * `test_3_1_i2c_master`: Master write with ACK checking.
  * `test_3_2_i2c_slave`: Slave receive with address matching.
  * `test_3_3_i2c_loopback`: Master-to-slave communication with open-drain driving.
  * `test_3_4_i2c_loopback_rx`: Slave transmit to master with clock stretching.
  * `test_3_5_i2c_10bit`: 10-bit addressing multi-core loopback (`11110xx` header, address low byte, and data payload).
  * `test_3_6_i2c_multi_master_arb`: Multi-master bus arbitration loss detection and safe back-off release.
* **Ethernet (2 Tests):**
  * `test_4_1_ethernet_tx`: 10BASE-T differential zero-skew Manchester transmission.
  * `test_4_2_ethernet_rx`: Dual-core Manchester edge decoding and preamble detection.
* **USB (2 Tests):**
  * `test_5_1_usb_tx`: Low-Speed (1.5 Mbps) 3-core pipelined NRZI transmission with bit-stuffing and EOP generation.
  * `test_5_2_usb_rx`: Low-Speed (1.5 Mbps) 3-core pipelined RX (Line sampler $\rightarrow$ NRZI unstuffer $\rightarrow$ Deserializer/CRC) with exact bit center-sampling and EOP SE0 detection.
* **Debug Controller (1 Test):**
  * `test_debug_controller`: Two-Wire Debug (`dvitantri_shodhana`) halt, resume, and register inspection across all 6 cores.
