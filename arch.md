# Protocol Emulator Architecture

This diagram illustrates the final **6-Core Accumulator Architecture** with Two-Wire Debug and 8-bit bidirectional IO mapped to Tiny Tapeout constraints on IHP 130nm CMOS5L.

To allow for full-duplex emulation across multiple protocols, the ASIC features **Six Independent Accumulator CPUs** (`संसाधक_०` through `संसाधक_५`). Each CPU is capable of addressing the shared 8-bit bidirectional protocol pins (`uio[7:0]`). The external host uses an SPI bus to program instruction RAMs and stream data, and a Two-Wire Debug interface (`dvitantri_shodhana`) to halt and inspect all cores in real-time.

```text
                               +-----------------------------+
                               |     EXTERNAL RP2040 HOST    |
                               +--+-----------------------+--+
                                  | SPI Bus               | Debug Bus (ui_in[3,2])
                                  | (CS, SCLK, MOSI)      | Run Signals (ui_in[7:4])
                                  | MISO (uo_out[0])      | DBG_DOUT (uo_out[7])
==================================|=======================|=================
                                  v                       v
                         +--------+--------+      +-------+-------+
                         |  HARDWARE SPI   |      |  द्वितन्त्री शोधन  |
                         | SLAVE & ROUTER  |      | DEBUG CNTRLR  |
                         +---+----------+--+      +---+-------+---+
                             |          |             |       |
         +-------------------+          +-------------+       +-------------+
         |                                                                  |
         v                                                                  v
  +---------------+   +---------------+   +---------------+   +---------------+   +---------------+   +---------------+
  | CPU 0 (Core 0)|   | CPU 1 (Core 1)|   | CPU 2 (Core 2)|   | CPU 3 (Core 3)|   | CPU 4 (Core 4)|   | CPU 5 (Core 5)|
  |  [Inst RAM]   |   |  [Inst RAM]   |   |  [Inst RAM]   |   |  [Inst RAM]   |   |  [Inst RAM]   |   |  [Inst RAM]   |
  |  [ FIFOs  ]   |   |  [ FIFOs  ]   |   |  [ FIFOs  ]   |   |  [ FIFOs  ]   |   |  [ FIFOs  ]   |   |  [ FIFOs  ]   |
  +-------+-------+   +-------+-------+   +-------+-------+   +-------+-------+   +-------+-------+   +-------+-------+
          |                   |                   |                   |                   |                   |
          +-------------------+-------------------+-------------------+-------------------+-------------------+
                                                  |
                                        [ SHARED REGISTERS ]
                                        [  SHARED_0 (0x9)  ]
                                        [  SHARED_1 (0xA)  ]
                                        [  SHARED_2 (0xB)  ]
                                        [  SHARED_3 (0xC)  ]
                                        [  SHARED_4 (0xD)  ]
                                        [  SHARED_5 (0xE)  ]
                                                  |
                                                  v
                                             [uio[7:0]]
                                         (8 Shared I/O Pins)
```

### Pin Breakdown (24 User I/O Pins)
According to the Tiny Tapeout pinout:
1. **`ui_in[7:0]` (8 Input Pins):** 
   - `ui_in[0]`: SPI `CS`
   - `ui_in[1]`: SPI `SCLK`
   - `ui_in[2]`: SPI `MOSI` / Two-Wire Debug `DIN`
   - `ui_in[3]`: Two-Wire Debug `SCLK`
   - `ui_in[4]`: `CPU0_RUN`
   - `ui_in[5]`: `CPU1_RUN`
   - `ui_in[6]`: `CPU2_RUN`
   - `ui_in[7]`: `CPU3_RUN` (Cores 4 and 5 run automatically by default and are halted/stepped via Debug controller)
2. **`uo_out[7:0]` (8 Output Pins):**
   - `uo_out[0]`: SPI `MISO`
   - `uo_out[1]`: Core 0 RX FIFO empty
   - `uo_out[2]`: Core 1 RX FIFO empty
   - `uo_out[3]`: Core 2 RX FIFO empty
   - `uo_out[4]`: Core 3 RX FIFO empty
   - `uo_out[5]`: Core 0 TX FIFO empty
   - `uo_out[6]`: Core 1 TX FIFO empty
   - `uo_out[7]`: Two-Wire Debug Serial Output (`DBG_DOUT`)
3. **`uio[7:0]` (8 Bidirectional Pins):**
   - All 8 pins (`uio[7:0]`) are shared across all 6 cores with non-contention OR-multiplexing and direction masking.
   - `ui_in[3]`: Unused / Spare
   - `ui_in[4]`: CPU 0 Run (Start/Stop)
   - `ui_in[5]`: CPU 1 Run (Start/Stop)
   - `ui_in[6]`: CPU 2 Run (Start/Stop)
   - `ui_in[7]`: CPU 3 Run (Start/Stop)
2. **`uo_out[7:0]` (8 Output Pins):**
   - `uo_out[0]`: SPI `MISO`
   - `uo_out[7:1]`: Hardwired to output the **FIFO Status Flags** (e.g., RX Empty, TX Full) for the cores. This allows the RP2040 host to instantly poll the FIFO health via physical pins instead of wasting SPI bandwidth.
3. **`uio_[7:0]` (8 Bidirectional Pins):** 
   - **`uio[3:0]`**: Shared and directly accessible by **CPU 0, 1, 2, and 3**. Their output directions and logic levels are logically OR-ed to prevent contention.
   - **`uio[7:4]`**: Unused / Available for future expansion.
