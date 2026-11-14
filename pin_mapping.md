# Detailed Pin Mapping and Hardware Interface

This document specifies the exact physical pinout and signal routing for the **6-Core Protocol Emulator ASIC** mapped to the 24 standard user I/O pins of the Tiny Tapeout framework on IHP 130nm CMOS5L (`ihp-sg13cmos5l`).

---

## 1. Physical Pin Assignment Table

| Tiny Tapeout Pin | Signal Name | Direction | Connected To | Description |
| :--- | :--- | :--- | :--- | :--- |
| **System Pins** | | | | |
| `clk` | `clk` | Input | All Internal Blocks | Main System Clock (50 MHz signoff) |
| `rst_n` | `rst_n` | Input | All Internal Blocks | Active-Low Asynchronous Global Reset |
| `ena` | `ena` | Input | Top-level Module | Module Enable (Tiny Tapeout power gating signal) |
| **Dedicated Inputs (`ui_in[7:0]`)** | | | | |
| `ui_in[0]` | `SPI_CS` | Input | Hardware SPI Slave | Active-Low Chip Select for instruction RAM & FIFO loading |
| `ui_in[1]` | `SPI_SCLK` | Input | Hardware SPI Slave | High-Speed SPI Clock from host MCU (RP2040) |
| `ui_in[2]` | `SPI_MOSI / DBG_DIN` | Input | SPI Slave & Debug Controller | Master-Out-Slave-In data line / Two-Wire Debug Serial Data In |
| `ui_in[3]` | `DBG_SCLK` | Input | Two-Wire Debug Controller | Dedicated Serial Clock for Two-Wire Debugger (`dvitantri_shodhana`) |
| `ui_in[4]` | `CPU0_RUN` | Input | CPU Core 0 | Execution Enable (1 = Run, 0 = Halt / Program Mode) |
| `ui_in[5]` | `CPU1_RUN` | Input | CPU Core 1 | Execution Enable (1 = Run, 0 = Halt / Program Mode) |
| `ui_in[6]` | `CPU2_RUN` | Input | CPU Core 2 | Execution Enable (1 = Run, 0 = Halt / Program Mode) |
| `ui_in[7]` | `CPU3_RUN` | Input | CPU Core 3 | Execution Enable (1 = Run, 0 = Halt / Program Mode) |
| **Dedicated Outputs (`uo_out[7:0]`)** | | | | |
| `uo_out[0]` | `SPI_MISO` | Output | Hardware SPI Slave | Master-In-Slave-Out line for reading back CPU RX FIFOs |
| `uo_out[1]` | `CPU0_RX_EMPTY` | Output | Core 0 RX FIFO | 1 = RX FIFO Empty, 0 = Data available to read |
| `uo_out[2]` | `CPU1_RX_EMPTY` | Output | Core 1 RX FIFO | 1 = RX FIFO Empty, 0 = Data available to read |
| `uo_out[3]` | `CPU2_RX_EMPTY` | Output | Core 2 RX FIFO | 1 = RX FIFO Empty, 0 = Data available to read |
| `uo_out[4]` | `CPU3_RX_EMPTY` | Output | Core 3 RX FIFO | 1 = RX FIFO Empty, 0 = Data available to read |
| `uo_out[5]` | `CPU0_TX_EMPTY` | Output | Core 0 TX FIFO | 1 = TX FIFO Empty, 0 = Data pending transmission |
| `uo_out[6]` | `CPU1_TX_EMPTY` | Output | Core 1 TX FIFO | 1 = TX FIFO Empty, 0 = Data pending transmission |
| `uo_out[7]` | `DBG_DOUT` | Output | Two-Wire Debug Controller | Serial Data Out for Two-Wire Debugger inspection (`dvitantri_shodhana`) |
| **Bidirectional I/O Pins (`uio[7:0]`)** | | | | |
| `uio[7:0]` | `IO[7:0]` | Bidi | CPU Cores 0-5 | Full 8-bit Bidirectional Protocol Bus (UART, SPI, I2C, USB, Ethernet, JTAG) |

---

## 2. Bidirectional Pin Sharing Architecture

All 8 bidirectional pins (`uio[7:0]`) are connected to all 6 cores:
* **Output Direction (`uio_oe[7:0]`):** Calculated as a logical OR across all six core direction registers:
  $$\text{uio\_oe}[7:0] = \bigvee_{k=0}^{5} \text{cpu}k\text{\_pin\_dir}$$
* **Output Data (`uio_out[7:0]`):** Each core's output data is masked by its direction before logical OR:
  $$\text{safe\_out}_k = \text{cpu}k\text{\_pin\_dir} \ \& \ \text{cpu}k\text{\_pin\_out}$$
  $$\text{uio\_out}[7:0] = \bigvee_{k=0}^{5} \text{safe\_out}_k$$
* **Input Data (`uio_in[7:0]`):** Broadcast simultaneously to all six cores. Any core can read the live line state at any cycle via `LOAD PIN_STATE`. Cores 4 and 5 run automatically (`run=1`) and can be halted individually via Two-Wire Debug.

---

## 3. Protocol Pin Mapping Reference

| Protocol | `uio[0]` | `uio[1]` | `uio[2]` | `uio[3]` | Notes |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **UART** | `TX` | `RX` | - | - | Core 0/1 on RX, Core 2 on TX, Core 3 Parity |
| **SPI Master** | `MOSI` | `MISO` | `SCLK` | `CS_N` | Full-Duplex Mode 0 |
| **I2C** | `SDA` | `SCL` | - | - | Open-Drain via `pin_dir` toggling with `pin_out=0` |
| **USB 1.1** | `D+` | `D-` | - | - | Low-Speed J/K states, SE0 and EOP |
| **10BASE-T** | `TX+` | `TX-` | `RX+` | `RX-` | Differential zero-skew Manchester transmission |
