// ==========================================
// Ethernet CPU 5: RX Deserializer & CRC Feeder
// Reads decoded bits from SHARED_2.
// Shifts them into a byte (LSB first).
// Feeds completed bytes into CRC_DATA (0xD) and TX_FIFO.
// ==========================================

    LOADI 16           // Bit 4 (SHARED_2 Valid) mask
    STORE R4

START:
    LOADI 8            // 8 bits per byte
    STORE R3
    LOADI 0            // Byte accumulator
    STORE R2

BIT_LOOP:
WAIT_CPU4:
    LOAD FLAGS
    STORE B
    LOAD R4
    AND B
    JMPNZ PROCESS      // Wait until SHARED_2 is valid
    JMP WAIT_CPU4

PROCESS:
    LOAD SHARED_2      // Read bit (Hardware clears valid flag)
    JMPNZ SET_MSB
    LOADI 0
    JMP ADD_TO_ACC

SET_MSB:
    LOADI 128          // 0x80 (MSB set)

ADD_TO_ACC:
    STORE B
    LOAD R2
    SHR
    ADD
    STORE R2

    // Decrement counter
    LOADI 1
    STORE B
    LOAD R3
    SUB
    STORE R3
    JMPNZ BIT_LOOP

    // Byte is complete!
    // 1. Feed to hardware CRC Accelerator (0xD)
    LOAD R2
    STORE CRC_DATA

    // 2. Push received byte to Host TX_FIFO
    LOAD R2
    STORE TX_FIFO

    JMP START
