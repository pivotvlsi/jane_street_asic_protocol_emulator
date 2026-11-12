// ==========================================
// SPI Master (Mode 0: CPOL=0, CPHA=0)
// Emulates full-duplex SPI Master on:
// Pin 0 (CS_N)  - Active-Low Output
// Pin 1 (SCK)   - Clock Output (Idle Low)
// Pin 2 (MOSI)  - Master Data Output (MSB first)
// Pin 3 (MISO)  - Master Data Input
// ==========================================

INIT:
    // Pin Directions: Pin 0, 1, 2 = Output (1), Pin 3 = Input (0)
    // 0111 = 7
    LOADI 7
    STORE PIN_DIR

    // Initial output states:
    SET1 0             // CS_N = 1 (Idle high)
    SET0 1             // SCK  = 0 (Mode 0: idle low)
    SET0 2             // MOSI = 0

    // Constant 1 in R7 for decrements
    LOADI 1
    STORE R7

MAIN_LOOP:
    // Wait for Host to supply a byte to transmit
    LOAD RX_FIFO
    STORE R2           // R2 = TX data byte

    // Assert CS_N low to begin SPI transfer
    SET0 0

    // Setup bit counter (8 bits)
    LOADI 8
    STORE R3

    // Clear RX accumulator for incoming MISO data
    LOADI 0
    STORE R4           // R4 = RX shift register

BIT_LOOP:
    // Mode 0: Setup MOSI while SCK is LOW
    // Check MSB of R2. R2 = R2 << 1 (Carry flag gets MSB)
    LOAD R2
    SHL
    STORE R2
    JMPC DRIVE_ONE

DRIVE_ZERO:
    SET0 2
    JMP SCK_HIGH

DRIVE_ONE:
    SET1 2

SCK_HIGH:
    // Clock low phase delay
    LOADI 4
    STORE TIMER_L
WAIT_CLK_LOW:
    LOAD TIMER_L
    JMPNZ WAIT_CLK_LOW

    // Rising edge: Assert SCK high
    SET1 1

    // Mode 0: Sample MISO on rising edge
    // Shift RX register left to prepare for new LSB
    LOAD R4
    SHL
    STORE R4

    // Read Pin 3 (MISO).
    LOAD PIN_STATE
    LOADIB 8           // Mask for Pin 3 (1<<3 = 8)
    AND
    JMPNZ SAMPLE_ONE
    JMP SAMPLE_DONE

SAMPLE_ONE:
    LOAD R7            // 1
    STORE B
    LOAD R4
    ADD
    STORE R4

SAMPLE_DONE:
    // Clock high phase delay
    LOADI 4
    STORE TIMER_L
WAIT_CLK_HIGH:
    LOAD TIMER_L
    JMPNZ WAIT_CLK_HIGH

    // Falling edge: SCK back to low
    SET0 1

    // Decrement bit counter (R3 = R3 - 1)
    LOAD R7
    STORE B
    LOAD R3
    SUB
    STORE R3
    JMPNZ BIT_LOOP

TRANSFER_DONE:
    // Deassert CS_N high (End of transfer)
    SET1 0

    // Send received MISO byte to Host TX FIFO
    LOAD R4
    STORE TX_FIFO

    // Loop back for next byte
    JMP MAIN_LOOP
