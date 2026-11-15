// ==========================================
// JTAG (IEEE 1149.1) Test Access Port Master
// Emulated on CPU Core (4-wire synchronous):
// Pin 0 (TCK)  - Test Clock (Idle Low) [Output]
// Pin 1 (TMS)  - Test Mode Select     [Output]
// Pin 2 (TDI)  - Test Data In to DUT   [Output]
// Pin 3 (TDO)  - Test Data Out from DUT[Input]
// ==========================================

INIT:
    // Pin Directions: Pin 0(TCK), 1(TMS), 2(TDI) = Output (1), Pin 3(TDO) = Input (0)
    // Binary: 0000_0111 = 0x07
    LOADI 7
    STORE PIN_DIR

    // Initial pin states:
    SET0 0             // TCK = 0 (Idle Low)
    SET1 1             // TMS = 1 (Default High)
    SET0 2             // TDI = 0

    // Constant 1 in R7 for decrements
    LOADI 1
    STORE R7

RESET_TAP:
    // Reset target TAP Controller: 5 consecutive TCK clocks with TMS=1
    // Guarantees transition to Test-Logic-Reset from any state
    LOADI 5
    STORE R3

TAP_RST_LOOP:
    SET1 1             // TMS = 1
    SET1 0             // TCK = 1
    LOADI 2
    STORE TIMER_L
WAIT_RST_HIGH:
    LOAD TIMER_L
    JMPNZ WAIT_RST_HIGH

    SET0 0             // TCK = 0
    LOADI 2
    STORE TIMER_L
WAIT_RST_LOW:
    LOAD TIMER_L
    JMPNZ WAIT_RST_LOW

    LOAD R3
    SUB R7
    STORE R3
    JMPNZ TAP_RST_LOOP

IDLE_TAP:
    // Transition from Test-Logic-Reset -> Run-Test/Idle: 1 clock with TMS=0
    SET0 1             // TMS = 0
    SET1 0             // TCK = 1
    SET0 0             // TCK = 0

MAIN_LOOP:
    // Wait for Host to supply command byte from RX FIFO:
    // [7:4] = Command (0x1 = Shift IR, 0x2 = Shift DR)
    // [3:0] = Bit count
    LOAD RX_FIFO
    STORE R2           // R2 = Command & length

    // Wait for Data Byte to shift
    LOAD RX_FIFO
    STORE R4           // R4 = TX Data (TDI)
    LOADI 0
    STORE R5           // R5 = RX Data (TDO captured)

    // Load bit counter (e.g. 8 bits)
    LOADI 8
    STORE R3

SHIFT_LOOP:
    // Check LSB or MSB of R4 for TDI
    LOAD R4
    SHR
    STORE R4
    JMPC TDI_ONE

TDI_ZERO:
    SET0 2             // TDI = 0
    JMP CLK_PULSE

TDI_ONE:
    SET1 2             // TDI = 1

CLK_PULSE:
    // Rising edge of TCK (Target samples TDI and TMS)
    SET1 0             // TCK = 1

    // Sample TDO on falling edge or while clock is high
    LOAD PIN_STATE
    SHR                // Shift bit 0
    SHR                // Shift bit 1
    SHR                // Shift bit 2
    SHR                // Carry = TDO (Pin 3)
    LOAD R5
    SHL
    STORE R5

    SET0 0             // TCK = 0

    LOAD R3
    SUB R7
    STORE R3
    JMPNZ SHIFT_LOOP

    // Push captured TDO result to Host TX FIFO
    LOAD R5
    STORE TX_FIFO
    JMP MAIN_LOOP
