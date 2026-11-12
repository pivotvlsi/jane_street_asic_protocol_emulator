# Detailed Pin Mapping and Hardware Interface

This document specifies the exact physical pinout and signal routing for the **Quad-Core Protocol Emulator ASIC** mapped to the 24 standard user I/O pins of the Tiny Tapeout framework on IHP 130nm CMOS5L (`ihp-sg13cmos5l`).

---

## 1. Physical Pin Assignment Table

| Tiny Tapeout Pin | Signal Name | Direction | Connected To | Description |
| :--- | :--- | :--- | :--- | :--- |
| **System Pins** | | | | |
| `clk` | `clk` | Input | All Internal Blocks | Main System Clock (100 MHz target) |
| `rst_n` | `rst_n` | Input | All Internal Blocks | Active-Low Asynchronous Global Reset |
| `ena` | `ena` | Input | Top-level Module | Module Enable (Tiny Tapeout power gating signal) |
| **Dedicated Inputs (`ui_in[7:0]`)** | | | | |
| `ui_in[0]` | `SPI_CS` | Input | Hardware SPI Slave | Active-Low Chip Select for instruction RAM & FIFO loading |
| `ui_in[1]` | `SPI_SCLK` | Input | Hardware SPI Slave | High-Speed SPI Clock from host MCU (RP2040) |
| `ui_in[2]` | `SPI_MOSI` | Input | Hardware SPI Slave | Master-Out-Slave-In data line for programming and TX data |
| `ui_in[3]` | `UNUSED` | Input | - | Spare / Unused input |
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
| `uo_out[7]` | `CPU2_TX_EMPTY` | Output | Core 2 TX FIFO | 1 = TX FIFO Empty, 0 = Data pending transmission |
| **Bidirectional I/O Pins (`uio[7:0]`)** | | | | |
| `uio[0]` | `IO0` | Bidi | CPU Cores 0-3 | Physical Protocol Pin 0 (e.g. UART TX, SPI MOSI, I2C SDA, USB D+, Eth TX+) |
| `uio[1]` | `IO1` | Bidi | CPU Cores 0-3 | Physical Protocol Pin 1 (e.g. UART RX, SPI MISO, I2C SCL, USB D-, Eth TX-) |
| `uio[2]` | `IO2` | Bidi | CPU Cores 0-3 | Physical Protocol Pin 2 (e.g. SPI SCLK, Eth RX+) |
| `uio[3]` | `IO3` | Bidi | CPU Cores 0-3 | Physical Protocol Pin 3 (e.g. SPI CS, Eth RX-) |
| `uio[7:4]` | `UNUSED` | Output | - | Unused (Driven to 0 with Output Enable disabled) |

---

## 2. Bidirectional Pin Sharing Architecture

The lower 4 bidirectional pins (`uio[3:0]`) are connected to all 4 cores:
* **Output Direction (`uio_oe[3:0]`):** Calculated as a logical OR across all four core direction registers:
  $$\text{uio\_oe}[3:0] = \text{cpu0\_pin\_dir} \mid \text{cpu1\_pin\_dir} \mid \text{cpu2\_pin\_dir} \mid \text{cpu3\_pin\_dir}$$
* **Output Data (`uio_out[3:0]`):** Each core's output data is masked by its direction before logical OR:
  $$\text{safe\_out}_k = \text{cpu}k\text{\_pin\_dir} \ \& \ \text{cpu}k\text{\_pin\_out}$$
  $$\text{uio\_out}[3:0] = \text{safe\_out}_0 \mid \text{safe\_out}_1 \mid \text{safe\_out}_2 \mid \text{safe\_out}_3$$
* **Input Data (`uio_in[3:0]`):** Broadcast simultaneously to all four cores. Any core can read the live line state at any cycle via `LOAD PIN_STATE`.

---

## 3. Protocol Pin Mapping Reference

| Protocol | `uio[0]` | `uio[1]` | `uio[2]` | `uio[3]` | Notes |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **UART** | `TX` | `RX` | - | - | Core 0/1 on RX, Core 2 on TX, Core 3 Parity |
| **SPI Master** | `MOSI` | `MISO` | `SCLK` | `CS_N` | Full-Duplex Mode 0 |
| **I2C** | `SDA` | `SCL` | - | - | Open-Drain via `pin_dir` toggling with `pin_out=0` |
| **USB 1.1** | `D+` | `D-` | - | - | Low-Speed J/K states, SE0 and EOP |
| **10BASE-T** | `TX+` | `TX-` | `RX+` | `RX-` | Differential zero-skew Manchester transmission |
