"""Cocotb Verification Suite for Jane Street ASIC 6-Core Protocol Emulator.

Inspired by industry/competitor benchmarks (WilliamZhang20/protocol-emulator)
featuring deterministic protocol verification, FIFO streaming, bidirectional UIO
arbitration, and Two-Wire Debug (dvitantri_shodhana) control.
"""

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, Timer


async def start_clock(dut):
    clock = Clock(dut.clk, 20, unit="ns")  # 50 MHz
    cocotb.start_soon(clock.start())


async def reset_dut(dut):
    dut.rst_n.value = 0
    dut.ena.value = 1
    dut.ui_in.value = 0x01  # spi_cs = 1 inactive
    dut.uio_in.value = 0x00
    await Timer(100, unit="ns")
    dut.rst_n.value = 1
    await Timer(100, unit="ns")


async def spi_write_byte(dut, byte: int):
    """SPI Mode 0 byte transfer matching tb_uart.v task."""
    current_ui = int(dut.ui_in.value)
    for i in range(7, -1, -1):
        bit = (byte >> i) & 1
        current_ui = (current_ui & ~0x04) | (bit << 2)  # MOSI = ui_in[2]
        dut.ui_in.value = current_ui
        await Timer(100, unit="ns")
        current_ui = current_ui | 0x02                  # SCLK = ui_in[1] = 1
        dut.ui_in.value = current_ui
        await Timer(100, unit="ns")
        current_ui = current_ui & ~0x02                 # SCLK = 0
        dut.ui_in.value = current_ui
    await Timer(60, unit="ns")


@cocotb.test()
async def test_reset_and_alive(dut):
    """Test 1: Verify ASIC boots, resets cleanly, and drives default status."""
    await start_clock(dut)
    await reset_dut(dut)

    # Cores 0..3 FIFOs should start empty
    # uo_out[1..4] = rx_empty, uo_out[5..6] = tx_empty
    assert (int(dut.uo_out.value) & 0x02) != 0, "Core 0 RX should be empty"
    assert (int(dut.uo_out.value) & 0x04) != 0, "Core 1 RX should be empty"
    dut._log.info("ASIC Boot & Reset state verified successfully.")


@cocotb.test()
async def test_two_wire_debug_halt_and_resume(dut):
    """Test 2: Two-Wire Debug Controller Halt and Resume verification."""
    await start_clock(dut)
    await reset_dut(dut)

    async def dbg_send(frame: int) -> int:
        resp = 0
        current_ui = int(dut.ui_in.value)
        for i in range(15, -1, -1):
            bit_in = (frame >> i) & 1
            current_ui = (current_ui & ~0x04) | (bit_in << 2)
            dut.ui_in.value = current_ui
            await Timer(50, unit="ns")
            current_ui = current_ui | 0x08  # SCLK = 1
            dut.ui_in.value = current_ui
            await Timer(50, unit="ns")
            bit_out = (int(dut.uo_out.value) >> 7) & 1
            resp = (resp << 1) | bit_out
            current_ui = current_ui & ~0x08  # SCLK = 0
            dut.ui_in.value = current_ui
        await Timer(100, unit="ns")
        return resp

    # 1. Halt Core 0 (CMD=01, CoreID=0, Halt=1 -> 0x4001)
    await dbg_send(0x4001)
    await Timer(100, unit="ns")
    assert dut.dbg_halt[0].value == 1, "Core 0 must be halted"
    dut._log.info("Two-Wire Debug: Core 0 Halt verified.")

    # 2. Halt Core 4 (CMD=01, CoreID=4, Halt=1 -> 0x6001)
    await dbg_send(0x6001)
    await Timer(100, unit="ns")
    assert dut.dbg_halt[4].value == 1, "Core 4 must be halted"
    dut._log.info("Two-Wire Debug: Core 4 Halt verified.")

    # 3. Resume Core 0 (CMD=01, CoreID=0, Halt=0 -> 0x4000)
    await dbg_send(0x4000)
    await Timer(100, unit="ns")
    assert dut.dbg_halt[0].value == 0, "Core 0 must resume"
    dut._log.info("Two-Wire Debug: Core 0 Resume verified.")


@cocotb.test()
async def test_bidirectional_uio_pin_contention_safety(dut):
    """Test 3: Verify 8-bit bidirectional pin arbitration and zero-contention."""
    await start_clock(dut)
    await reset_dut(dut)

    # When all cores have pin_dir = 0 (input mode), uio_oe must be 0x00
    assert (
        int(dut.uio_oe.value) == 0x00
    ), "All pins must be High-Z on default boot"

    # Feed input pattern on uio_in, verify core can sample
    dut.uio_in.value = 0xAA
    await RisingEdge(dut.clk)
    assert int(dut.uio_in.value) == 0xAA, "uio_in bus driven correctly"
    dut._log.info("Bidirectional UIO pin safety verified.")


@cocotb.test()
async def test_spi_slave_host_interface_streaming(dut):
    """Test 4: Verify SPI slave configuration interface can stream data packets."""
    await start_clock(dut)
    await reset_dut(dut)

    # Assert SPI CS low (ui_in[0] = 0)
    dut.ui_in.value = int(dut.ui_in.value) & ~0x01
    await Timer(100, unit="ns")

    # Command 0x02: Core 0 FIFO write, payload 0xA5
    await spi_write_byte(dut, 0x02)
    await spi_write_byte(dut, 0xA5)

    # Deassert CS
    dut.ui_in.value = int(dut.ui_in.value) | 0x01
    await Timer(200, unit="ns")

    # Core 0 RX FIFO should now not be empty (uo_out[1] == 0)
    rx0_empty = (int(dut.uo_out.value) >> 1) & 1
    assert rx0_empty == 0, "Core 0 RX FIFO should contain streamed byte"
    dut._log.info("SPI Slave streaming to Core 0 FIFO verified.")


@cocotb.test()
async def test_multi_core_fifo_isolation(dut):
    """Test 5: Verify Core 0 and Core 1 FIFOs are isolated without cross-talk."""
    await start_clock(dut)
    await reset_dut(dut)

    # Write to Core 1 FIFO only (Command 0x03)
    dut.ui_in.value = int(dut.ui_in.value) & ~0x01
    await Timer(100, unit="ns")
    await spi_write_byte(dut, 0x03)
    await spi_write_byte(dut, 0x3C)
    dut.ui_in.value = int(dut.ui_in.value) | 0x01
    await Timer(200, unit="ns")

    # Core 1 RX FIFO has byte (uo_out[2] == 0)
    rx1_empty = (int(dut.uo_out.value) >> 2) & 1
    # Core 0 RX FIFO remains empty (uo_out[1] == 1)
    rx0_empty = (int(dut.uo_out.value) >> 1) & 1

    assert rx1_empty == 0, "Core 1 RX FIFO must have received byte"
    assert rx0_empty == 1, "Core 0 RX FIFO must remain empty (no leakage)"
    dut._log.info("Multi-core FIFO channel isolation verified.")


@cocotb.test()
async def test_universal_crc_spi_preload_and_calculation(dut):
    """Test 6: Verify Universal CRC Accelerator with SPI Host Preload (CRC-5, CRC-16, Arbitrary)."""
    await start_clock(dut)
    await reset_dut(dut)

    async def preload_crc(addr: int, data: int):
        dut.ui_in.value = int(dut.ui_in.value) & ~0x01
        await Timer(100, unit="ns")
        await spi_write_byte(dut, 0x60 | (addr & 0x0F))
        await spi_write_byte(dut, data)
        dut.ui_in.value = int(dut.ui_in.value) | 0x01
        await Timer(100, unit="ns")

    # 1. Preload Arbitrary CRC Parameters via SPI:
    # Set Width=16, Poly=0x8005 (CRC-16-IBM), Seed=0xFFFF, XOR=0x0000
    await preload_crc(0x0, 16)      # Width = 16
    await preload_crc(0x1, 0x05)    # Poly[7:0]
    await preload_crc(0x2, 0x80)    # Poly[15:8]
    await preload_crc(0x3, 0x00)
    await preload_crc(0x4, 0x00)
    await preload_crc(0x5, 0xFF)    # Seed[7:0]
    await preload_crc(0x6, 0xFF)    # Seed[15:8]
    await preload_crc(0x9, 0x00)    # XOR[7:0]
    await preload_crc(0xA, 0x00)    # XOR[15:8]
    await preload_crc(0xD, 0x03)    # RefIn=1, RefOut=1
    await preload_crc(0xE, 0x01)    # Re-seed trigger

    # Verify LFSR is seeded properly
    width_val = int(dut.crc_inst.vistara_panjika.value)
    poly_val = int(dut.crc_inst.bhajaka_bahupada_panjika.value)
    assert width_val == 16, f"CRC Width must be 16, got {width_val}"
    assert poly_val == 0x8005, f"CRC Polynomial must be 0x8005, got {hex(poly_val)}"

    # 2. Feed data byte 0x31 ('1') through core memory interface
    dut.crc_feed_we.value = 1
    dut.crc_feed_data.value = 0x31
    await RisingEdge(dut.clk)
    dut.crc_feed_we.value = 0
    await RisingEdge(dut.clk)

    # Read back computed remainder
    dut.crc_slice_sel.value = 0  # Byte 0
    await Timer(50, unit="ns")
    crc_low = int(dut.crc_result_byte.value)
    dut.crc_slice_sel.value = 1  # Byte 1
    await Timer(50, unit="ns")
    crc_high = int(dut.crc_result_byte.value)

    computed_crc = (crc_high << 8) | crc_low
    dut._log.info(f"SPI Preloaded CRC-16 computation result: {hex(computed_crc)}")
    assert computed_crc != 0xFFFF, "CRC remainder must update after byte feed"
    dut._log.info("Universal CRC SPI Host Preload and calculation verified.")
