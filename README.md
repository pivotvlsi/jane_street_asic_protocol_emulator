# 6-Core Protocol Emulator ASIC

This project is an official entry for the **Jane Street Hardware Challenge / ASIC Protocol Emulator Competition**, designed and developed by the team at **[PivotVLSI](https://pivotvlsi.in/)**. 

## Project Overview

The **6-Core Protocol Emulator** is a novel, highly optimized hardware-software co-design targeted for the **IHP 130nm CMOS5L PDK (`ihp-sg13cmos5l`)** on Tiny Tapeout, running at a signed-off **50 MHz** system clock.

Instead of using fixed-function hardware macros (like a dedicated hardware UART, SPI, or I2C peripheral), this ASIC features **six custom-designed, 8-bit accumulator-based soft-cores** (`संसाधक_०` through `संसाधक_५`) running concurrently in parallel. The cores execute a split-stream 4-bit nibble instruction ISA, share access to an 8-bit bidirectional protocol bus (`uio[7:0]`), feature hardware-synchronized shared pipeline registers (`SHARED_0` .. `SHARED_5`), and include a dedicated Two-Wire Debug controller (`dvitantri_shodhana`) to halt and inspect execution state in real-time.

This "software-defined peripheral" approach provides immense flexibility, allowing the ASIC to act as a UART transceiver, SPI Master, I2C Controller, USB Low-Speed bit-banger, or 10BASE-T Ethernet transceiver, simply by dynamically loading assembly firmware into on-chip RAM over a high-speed SPI configuration bus.

## Key Features
*   **6-Core Architecture:** 6 independent 8-bit accumulator cores running in parallel at 50 MHz.
*   **Two-Wire Debug Controller (`dvitantri_shodhana`):** Hardware debug tap to halt, resume, and read all internal registers (ACC, B, FLAGS, PC0, PC1, PC2, PIN_DIR, PIN_OUT) via synchronous serial frames (`ui_in[3]`, `ui_in[2]`, `uo_out[7]`).
*   **8-Bit Bidirectional Protocol Bus (`uio[7:0]`):** Clean direction-masked OR-multiplexed physical pin interface across all 6 cores.
*   **Zero Dedicated Hardware Peripherals:** All protocols are 100% bit-banged in software firmware.
*   **Dynamic Instruction RAM:** Firmware routines are dynamically loaded and hot-swapped into on-chip RAM over SPI by the host MCU (RP2040).
*   **Multi-Core Pipelining & Collaboration:** Cores can snoop the same wire simultaneously (e.g., Core 0 sampling UART data while Core 1 handles deserialization and Core 3 evaluates Parity in real-time; or Core 0 and Core 1 driving zero-skew differential signals for Ethernet TX+ / TX-).
*   **Rich Protocol Support:**
    *   **UART:** Basic TX, Dynamic Baud, Streaming TX, Noise-Resilient Center-Sampling RX, Framing Error & Parity Checking (`8E1`).
    *   **SPI:** Mode 0 full-duplex bit-banging master.
    *   **I2C:** Master TX/RX, Slave TX/RX with hardware clock stretching support.
    *   **USB 1.1 Low-Speed (1.5 Mbps):** 3-core pipelined transmission with automated hardware bit-stuffing, NRZI encoding, and EOP generation.
    *   **10BASE-T Ethernet (10 Mbps):** 4-core zero-skew differential transmission and 2-core Manchester edge decoding.
*   **Hardware FIFOs & Status Flags:** 8-byte RX and TX FIFOs per core with real-time overrun detection mapped to the `STATUS_FLAGS` register (Bit 6) and dedicated status output pins.

## Physical Design & Tapeout Metrics (IHP 130nm CMOS5L)

The physical layout was hardened and signed off via the automated LibreLane / OpenROAD physical design flow targeting the **IHP 130nm CMOS5L** process (`ihp-sg13cmos5l`). All DRC, LVS, antenna, and timing checks passed with **zero violations**.

| Metric Category | Parameter | Reported Value | Signoff Status |
| :--- | :--- | :--- | :--- |
| **Die & Floorplan** | Die Dimensions / Area | $1724.16\ \mu\text{m} \times 710.64\ \mu\text{m}$ ($1.225\ \text{mm}^2$) | **PASS** (8x4 Tile Size) |
| | Core Dimensions / Area | $1721.28\ \mu\text{m} \times 706.86\ \mu\text{m}$ ($1.217\ \text{mm}^2$) | **PASS** |
| | Standard Cell Utilization | $52.59\%$ | **PASS** (Optimal routability) |
| **Cell Count** | Total Cell Instances | 98,310 cells | **PASS** |
| | Standard Logic Cells | 35,183 cells ($635,328\ \mu\text{m}^2$) | **PASS** |
| | Sequential Elements (DFFs) | 5,492 cells | **PASS** |
| | Combinational Cells | 19,368 cells | **PASS** |
| | Clock Tree Buffers / Inverters | 738 cells (532 buffers + 206 inverters) | **PASS** |
| | Timing Repair Buffers | 9,187 cells | **PASS** |
| | Physical Fill Cells | 63,127 cells | **PASS** |
| **Clock & Timing** | Operating Clock Frequency | 50.0 MHz ($T_{\text{period}} = 20.0\ \text{ns}$) | **PASS** |
| | Worst Setup Slack (WNS) | $+4.42\ \text{ns}$ (Corner: `nom_slow_1p08V_125C`) | **PASS** (Zero violations) |
| | Typical Setup Slack (WNS) | $+9.75\ \text{ns}$ (Corner: `nom_typ_1p20V_25C`) | **PASS** (Zero violations) |
| | Fast Setup Slack (WNS) | $+11.99\ \text{ns}$ (Corner: `nom_fast_1p32V_m40C`) | **PASS** (Zero violations) |
| | Worst Hold Slack (WHS) | $+0.105\ \text{ns}$ (Corner: `nom_fast_1p32V_m40C`) | **PASS** (Zero violations) |
| | Total Negative Slack (TNS) | $0.00\ \text{ns}$ | **PASS** (Clean closure) |
| | Max Clock Skew | $0.39\ \text{ns}$ (setup) / $0.54\ \text{ns}$ (hold) | **PASS** |
| **Routing & Physical Verification** | Total Routed Wirelength | $1,263,927\ \mu\text{m}$ ($1.264\ \text{m}$) | **PASS** |
| | Detailed Routing DRC Errors | **0 errors** (TritonRoute) | **PASS** |
| | Magic Signoff DRC Errors | **0 errors** | **PASS** |
| | KLayout Signoff DRC Errors | **0 errors** (`drc_sg13cmos5l.xml`) | **PASS** |
| | Netgen LVS Device/Net Differences | **0 errors** (100% matched) | **PASS** |
| | Antenna Violations | **0 violating nets / pins** | **PASS** (32 antenna diodes) |
| **Power & IR Drop** | Total Chip Power Consumption | $22.02\ \text{mW}$ | **PASS** |
| | Internal Power / Switching Power | $17.67\ \text{mW}$ / $4.30\ \text{mW}$ | **PASS** |
| | Leakage Power | $40.55\ \mu\text{W}$ | **PASS** |
| | Max Voltage Drop (VPWR / VGND) | $0.31\ \text{mV}$ | **PASS** |

## Documentation Navigation
To understand the architecture and how to run the verification suite, please refer to the following documentation:

1.  **[Master Feature Specification](features.md)**: Comprehensive capability matrix, protocol breakdown, and hardware subsystem details.
2.  **[Architecture Overview](arch.md)**: Details the CPU internals, memory maps, inter-core communication, and the shared bus infrastructure.
3.  **[ISA Specification](isa_spec.md)**: The complete instruction set for the custom split-stream CPU.
4.  **[Pin Mapping](pin_mapping.md)**: The physical pinout mapping for the Tiny Tapeout ASIC framework.
5.  **[Verification Guide](verif_readme.md)**: Instructions on how to compile the assembly firmware and run the automated testbenches.
6.  **[Limitations & Constraints](limitations.md)**: An honest look at the architectural bottlenecks, software debugging complexities, and theoretical maximum throughput.

---
*Built with silicon passion by [PivotVLSI](https://pivotvlsi.in/)*
