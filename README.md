# Quad-Core Protocol Emulator ASIC

This project is an official entry for the **Jane Street Hardware Challenge / ASIC Protocol Emulator Competition**, designed and developed by the team at **[PivotVLSI](https://pivotvlsi.in/)**. 

## Project Overview

The **Quad-Core Protocol Emulator** is a novel, highly optimized hardware-software co-design targeted for the **IHP 130nm CMOS5L PDK (`ihp-sg13cmos5l`)** on Tiny Tapeout, running at a native **100 MHz** system clock.

Instead of using fixed-function hardware macros (like a dedicated hardware UART, SPI, or I2C peripheral), this ASIC features **four custom-designed, 8-bit accumulator-based soft-cores** running concurrently in parallel. The cores execute a split-stream 4-bit nibble instruction ISA, share access to external bidirectional pins, and emulate complex communication protocols entirely in software (cycle-accurate bit-banging).

This "software-defined peripheral" approach provides immense flexibility, allowing the ASIC to act as a UART transceiver, SPI Master, I2C Controller, USB Low-Speed bit-banger, or 10BASE-T Ethernet transceiver, simply by dynamically loading assembly firmware into on-chip RAM over a high-speed SPI configuration bus.

## Key Features
*   **Quad-Core Architecture:** 4 independent 8-bit accumulator cores running in parallel at 100 MHz.
*   **Zero Dedicated Hardware Peripherals:** All protocols are 100% bit-banged in software firmware.
*   **Dynamic Instruction RAM:** Firmware routines are dynamically loaded and hot-swapped into on-chip RAM over SPI by the host MCU (RP2040).
*   **Multi-Core Pipelining & Collaboration:** Cores can snoop the same wire simultaneously (e.g., Core 0 sampling UART data while Core 1 handles deserialization and Core 3 evaluates Parity in real-time; or Core 0 and Core 1 driving zero-skew differential signals for Ethernet TX+ / TX-).
*   **Rich Protocol Support:**
    *   **UART:** Basic TX, Dynamic Baud, Streaming TX, Noise-Resilient Center-Sampling RX, Framing Error & Parity Checking (`8E1`).
    *   **SPI:** Mode 0 full-duplex bit-banging master.
    *   **I2C:** Master TX/RX, Slave TX/RX with hardware clock stretching support.
    *   **USB 1.1 Low-Speed (1.5 Mbps):** 3-core pipelined transmission with automated hardware bit-stuffing, NRZI encoding, and EOP generation.
    *   **10BASE-T Ethernet (10 Mbps):** 4-core zero-skew differential transmission and 2-core Manchester edge decoding.
*   **Hardware FIFOs & Status Flags:** 8-byte RX and TX FIFOs per core with real-time overrun detection mapped to the `FLAGS` register (Bit 6) and dedicated status output pins.

## Documentation Navigation
To understand the architecture and how to run the verification suite, please refer to the following documentation:

1.  **[Architecture Overview](arch.md)**: Details the CPU internals, memory maps, inter-core communication, and the shared bus infrastructure.
2.  **[ISA Specification](isa_spec.md)**: The complete instruction set for the custom split-stream CPU.
3.  **[Pin Mapping](pin_mapping.md)**: The physical pinout mapping for the Tiny Tapeout ASIC framework.
4.  **[Verification Guide](verif_readme.md)**: Instructions on how to compile the assembly firmware and run the automated testbenches.
5.  **[Limitations & Constraints](limitations.md)**: An honest look at the architectural bottlenecks, software debugging complexities, and theoretical maximum throughput.

---
*Built with silicon passion by [PivotVLSI](https://pivotvlsi.in/)*
