# Protocol Emulator Architecture

This diagram illustrates the final **6-Core Accumulator Architecture** with Two-Wire Debug and 8-bit bidirectional IO mapped to Tiny Tapeout constraints on IHP 130nm CMOS5L.

To allow for full-duplex emulation across multiple protocols, the ASIC features **Six Independent Accumulator CPUs** (`संसाधक_०` through `संसाधक_५`). Each CPU is capable of addressing the shared 8-bit bidirectional protocol pins (`uio[7:0]`). The external host uses an SPI bus to program instruction RAMs and stream data, and a Two-Wire Debug interface (`dvitantri_shodhana`) to halt and inspect all cores in real-time.

```text
                               +-----------------------------+
                               |     EXTERNAL RP2040 HOST    |
                               +--+-----------------------+--+
                                  | SPI Bus               | Debug Bus (ui_in[3,2])
                                  | (CS, SCLK, MOSI)      | DBG_DOUT (uo_out[7])
                                  | MISO (uo_out[0])      | INTERRUPT (uo_out[1])
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
   - `ui_in[7:4]`: Unused (tied off internally)
2. **`uo_out[7:0]` (8 Output Pins):**
   - `uo_out[0]`: SPI `MISO`
   - `uo_out[1]`: Global Host `INTERRUPT` (logical OR of all core event/FIFO flags)
   - `uo_out[6:2]`: Unused (tied to 1'b0)
   - `uo_out[7]`: Two-Wire Debug Serial Output (`DBG_DOUT`)
3. **`uio[7:0]` (8 Bidirectional Pins):**
   - `uio[3:0]`: Active Protocol Bus (`uio[0]`: D+/TX/SDA, `uio[1]`: D-/RX/SCL, `uio[2]`: ETH RX, `uio[3]`: SPI CS).
   - `uio[7:4]`: Unused / Reserved expansion.
