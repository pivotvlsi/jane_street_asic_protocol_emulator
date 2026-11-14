// ==========================================
// I2C 10-bit Slave Receive
// Emulates 10-bit I2C Slave on Pin 0 (SDA) and Pin 1 (SCL)
// ==========================================
// Matches 10-bit addressing transaction:
// Receives 3 bytes (Byte 1: Header, Byte 2: AddrLow, Byte 3: Payload Data)
// Outputs payload data byte to TX_FIFO.

START:
    LOADI 1
    STORE R6
    LOADI 2
    STORE R7
    LOADI 3
    STORE R4

    LOADI 0
    STORE PIN_DIR      // High-Z

WAIT_START:
    // Wait for SCL=1, SDA=0 (Binary 2)
    LOAD R4
    STORE B
    LOAD PIN_STATE
    AND B
    STORE R2
    LOAD R7
    STORE B
    LOAD R2
    SUB
    JMPNZ WAIT_START

    // Set byte counter = 3
    LOAD R4
    STORE R5

READ_BYTE:
    LOADI 8
    STORE R3           // Bit counter
    LOADI 0
    STORE R2           // Accumulator

BIT_LOOP:
    // Wait for SCL LOW
WAIT_SCL_LOW:
    LOAD R7
    STORE B
    LOAD PIN_STATE
    AND B
    JMPNZ WAIT_SCL_LOW

    // Wait for SCL HIGH
WAIT_SCL_HIGH:
    LOAD R7
    STORE B
    LOAD PIN_STATE
    AND B
    JMPNZ SCL_IS_HIGH
    JMP WAIT_SCL_HIGH

SCL_IS_HIGH:
    // Shift R2 left
    LOAD R2
    SHL
    STORE R2

    // Read SDA
    LOAD R6
    STORE B
    LOAD PIN_STATE
    AND B
    STORE B

    // Add bit to R2
    LOAD R2
    ADD
    STORE R2

    // Decrement bit counter
    LOAD R6
    STORE B
    LOAD R3
    SUB
    STORE R3
    JMPNZ BIT_LOOP

    // Decrement byte counter
    LOAD R6
    STORE B
    LOAD R5
    SUB
    STORE R5
    JMPNZ READ_BYTE

    // All 3 bytes read, R2 holds the payload data byte!
    LOAD R2
    STORE TX_FIFO

    // Wait for next transaction
    JMP START
