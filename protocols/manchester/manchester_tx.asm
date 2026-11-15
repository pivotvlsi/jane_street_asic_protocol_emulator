// ==========================================
// Manchester Encoder & Transmitter (IEEE 802.3 / 10BASE-T style)
// Emulated on CPU Core:
// Pin 0 (MAN_TX) - Single-Ended Manchester Output
// Pin 1 (MAN_N)  - Complementary Output (Differential)
//
// Manchester Encoding Rules:
// Bit 0: Rising Edge at midpoint  (0 in first half, 1 in second half)
// Bit 1: Falling Edge at midpoint (1 in first half, 0 in second half)
// ==========================================

INIT:
    // Pin Directions: Pin 0 and Pin 1 = Output (1)
    // Binary: 0000_0011 = 0x03
    LOADI 3
    STORE PIN_DIR

    // Idle Line: Both pins low (or differential idle)
    SET0 0
    SET0 1

    LOADI 1
    STORE R7           // Constant 1 for decrement

MAIN_LOOP:
    // Wait for byte to transmit from Host FIFO
    LOAD RX_FIFO
    STORE R2           // R2 = 8-bit payload to transmit

    // Bit counter = 8
    LOADI 8
    STORE R3

BIT_LOOP:
    // Extract MSB of R2 into Carry
    LOAD R2
    SHL
    STORE R2
    JMPC SEND_ONE

SEND_ZERO:
    // Bit '0': LOW for 1st half, HIGH for 2nd half
    SET0 0             // Pin 0 = 0
    SET1 1             // Pin 1 = 1 (inverted)
    LOADI 4            // Half-bit delay period
    STORE TIMER_L
WAIT_ZERO_HALF1:
    LOAD TIMER_L
    JMPNZ WAIT_ZERO_HALF1

    SET1 0             // Pin 0 = 1 (Rising edge transition!)
    SET0 1             // Pin 1 = 0
    LOADI 4
    STORE TIMER_L
WAIT_ZERO_HALF2:
    LOAD TIMER_L
    JMPNZ WAIT_ZERO_HALF2
    JMP NEXT_BIT

SEND_ONE:
    // Bit '1': HIGH for 1st half, LOW for 2nd half
    SET1 0             // Pin 0 = 1
    SET0 1             // Pin 1 = 0
    LOADI 4            // Half-bit delay period
    STORE TIMER_L
WAIT_ONE_HALF1:
    LOAD TIMER_L
    JMPNZ WAIT_ONE_HALF1

    SET0 0             // Pin 0 = 0 (Falling edge transition!)
    SET1 1             // Pin 1 = 1
    LOADI 4
    STORE TIMER_L
WAIT_ONE_HALF2:
    LOAD TIMER_L
    JMPNZ WAIT_ONE_HALF2

NEXT_BIT:
    LOAD R3
    SUB R7
    STORE R3
    JMPNZ BIT_LOOP

    // End of byte: return to Idle
    SET0 0
    SET0 1
    JMP MAIN_LOOP
