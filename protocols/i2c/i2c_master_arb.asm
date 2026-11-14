// ==========================================
// I2C Master with Arbitration Loss Detection (Optimized)
// Emulates I2C on Pin 0 (SDA) and Pin 1 (SCL)
// ==========================================

START_COND:
    LOADI 1
    STORE R6           // Constant 1
    LOADI 2
    STORE R7           // Constant 2
    LOADI 3
    STORE R4           // Constant 3

    SET0 0
    SET0 1

    // Start condition: SDA Low
    LOAD R6
    STORE PIN_DIR

    // Pull SCL Low
    LOAD R4
    STORE PIN_DIR

WRITE_BYTE:
    LOAD RX_FIFO
    STORE R2
    LOADI 8
    STORE R3

BIT_LOOP:
    LOAD R2
    SHL
    STORE R2
    JMPC SEND_ONE

SEND_ZERO:
    LOAD R4
    STORE PIN_DIR
    LOAD R6
    STORE PIN_DIR
    JMP WAIT_SCL

SEND_ONE:
    LOAD R7
    STORE R4           // R4 = 2 (indicates '1' was sent)
    STORE PIN_DIR
    LOADI 0
    STORE PIN_DIR

WAIT_SCL:
    // If R4 == 2, check arbitration
    LOAD R7
    STORE B
    LOAD R4
    SUB
    JMPNZ PULL_SCL_LOW

    // Sent '1': sample SDA (PIN_STATE & 1)
    LOAD R6
    STORE B
    LOAD PIN_STATE
    AND B
    JMPNZ RESTORE_R4

    // ARBITRATION LOST!
    LOADI 0
    STORE PIN_DIR
    LOADI 0xEE         // 0xEE = Arbitration Lost code
    STORE TX_FIFO
    JMP START_COND

RESTORE_R4:
    LOAD R6
    STORE B
    LOAD R7
    ADD
    STORE R4           // R4 = 3

PULL_SCL_LOW:
    LOAD R4
    STORE PIN_DIR

    LOAD R6
    STORE B
    LOAD R3
    SUB
    STORE R3
    JMPNZ BIT_LOOP

    JMP WRITE_BYTE
