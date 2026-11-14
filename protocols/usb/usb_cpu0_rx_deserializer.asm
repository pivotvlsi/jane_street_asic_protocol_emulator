// ==========================================
// USB 1.1 Low-Speed RX: CPU 0 Deserializer & CRC Feeder
// Reads clean payload bits from SHARED_3 (0, 1, or 2=EOP).
// - Assembles bits LSB-first into 8-bit bytes.
// - Feeds completed bytes into Universal CRC Engine (0xD).
// - Pushes completed bytes to Host TX_FIFO (0x4).
// ==========================================

START_PACKET:
    LOADI 8            // 8 bits per byte
    STORE R3
    LOADI 0            // Byte accumulator
    STORE R2

BIT_LOOP:
    LOAD SHARED_3      // Blocks until CPU 5 writes to SHARED_3
    STORE B            // B = incoming bit

    // Check if EOP token (2)
    LOADI 2
    SUB B
    JMPNZ ACCUMULATE_BIT

    // EOP reached before byte finished: restart packet
    JMP START_PACKET

ACCUMULATE_BIT:
    // If incoming bit is 1, set MSB (0x80)
    LOAD B
    JMPNZ SET_MSB
    LOADI 0
    JMP SHIFT_ACC

SET_MSB:
    LOADI 128          // 0x80

SHIFT_ACC:
    STORE B
    LOAD R2
    SHR
    ADD B
    STORE R2

    // Decrement bit counter
    LOADI 1
    STORE B
    LOAD R3
    SUB B
    STORE R3
    JMPNZ BIT_LOOP

BYTE_COMPLETE:
    // 1. Feed completed byte to Hardware Universal CRC Engine (0xD)
    LOAD R2
    STORE CRC_DATA

    // 2. Push received byte to Host TX_FIFO (0x4)
    LOAD R2
    STORE TX_FIFO

    JMP START_PACKET
