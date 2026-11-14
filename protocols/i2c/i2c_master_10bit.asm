// ==========================================
// I2C 10-bit Master (Transmits 10-bit address frame and data)
// Emulates 10-bit I2C Master on Pin 0 (SDA) and Pin 1 (SCL)
// ==========================================
// Protocol sequence:
// 1. START condition (SDA High -> Low while SCL High)
// 2. 1st Address Byte (11110 || A[9:8] || 0) from RX_FIFO
// 3. 2nd Address Byte (A[7:0]) from RX_FIFO
// 4. Data Payload Byte from RX_FIFO

START_COND:
    LOADI 1
    STORE R6
    LOADI 2
    STORE R7
    LOADI 3
    STORE R4

    SET0 0
    SET0 1

    // SDA Output 0, SCL High-Z -> Start Condition!
    LOAD R6
    STORE PIN_DIR

    // Hold START condition
    LOADI 60
    STORE TIMER_L
START_DELAY:
    LOAD TIMER_L
    JMPNZ START_DELAY

    // Pull SCL Low
    LOAD R4
    STORE PIN_DIR

    // Transmit 3 bytes: Header, AddrLow, Data
    LOAD R4
    STORE R5           // Byte counter = 3

NEXT_BYTE:
    LOAD RX_FIFO
    STORE R2           // Byte to send
    LOADI 8
    STORE R3           // Bit counter = 8

BIT_LOOP:
    LOADI 48
    STORE TIMER_L
DELAY_LOW:
    LOAD TIMER_L
    JMPNZ DELAY_LOW

    LOAD R2
    SHL
    STORE R2
    JMPC SEND_ONE

SEND_ZERO:
    LOAD R4
    STORE PIN_DIR
    LOAD R6
    STORE PIN_DIR
    JMP WAIT_SCL_HIGH

SEND_ONE:
    LOAD R7
    STORE PIN_DIR
    STORE B
    SUB
    STORE PIN_DIR

WAIT_SCL_HIGH:
    LOADI 24
    STORE TIMER_L
DELAY_HIGH:
    LOAD TIMER_L
    JMPNZ DELAY_HIGH

    // Pull SCL Low
    LOAD R4
    STORE PIN_DIR

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
    JMPNZ NEXT_BYTE

    // Frame done, repeat for next transaction
    JMP START_COND
