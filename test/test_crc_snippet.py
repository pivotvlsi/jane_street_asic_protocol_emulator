    # ------------------------------------------------------------------------
    # CRC Preload Helpers
    # ------------------------------------------------------------------------
    async def preload_crc_reg(addr: int, data: int):
        dut.ui_in.value = int(dut.ui_in.value) & ~0x01  # CS = 0
        await Timer(100, unit="ns")
        await spi_write_byte(dut, 0x60 | (addr & 0x0F))
        await spi_write_byte(dut, data)
        dut.ui_in.value = int(dut.ui_in.value) | 0x01   # CS = 1
        await Timer(100, unit="ns")

    # Preload CRC-5 USB Token Parameters: Poly=0x05, Seed=0x1F, XOR=0x1F, Width=5
    await preload_crc_reg(0x0, 5)     # Width = 5
    await preload_crc_reg(0x1, 0x05)  # Poly[7:0] = 0x05
    await preload_crc_reg(0x2, 0x00)
    await preload_crc_reg(0x5, 0x1F)  # Seed[7:0] = 0x1F
    await preload_crc_reg(0x6, 0x00)
    await preload_crc_reg(0x9, 0x1F)  # XOR[7:0] = 0x1F
    await preload_crc_reg(0xA, 0x00)
    await preload_crc_reg(0xD, 0x00)  # RefIn=0, RefOut=0
    await preload_crc_reg(0xE, 0x00)  # Trigger Re-seed
