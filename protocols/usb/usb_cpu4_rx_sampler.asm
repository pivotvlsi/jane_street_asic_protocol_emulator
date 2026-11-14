// ==========================================
// USB 1.1 Low-Speed RX: CPU 4 Line Sampler
// Samples Pin 0 (D+) and Pin 1 (D-) on UIO[1:0].
// Detects SOP (J->K transition), center-samples at exactly 33-cycle intervals,
// and detects SE0 (D+=0, D-=0) for EOP.
// Pushes sampled state to SHARED_2:
//   0 = J State (D+=0, D-=1)
//   1 = K State (D+=1, D-=0)
//   2 = SE0 / EOP (D+=0, D-=0)
// ==========================================

    // Ensure pins are inputs
    LOADI 0
    STORE PIN_DIR

WAIT_IDLE:
    // Wait until bus is in Idle J-State (Pin 0=0, Pin 1=1 -> Pin value 2)
    LOAD PIN_STATE
    STORE B
    LOADI 3
    AND B
    STORE B
    LOADI 2            // J-State has value 2
    SUB B
    JMPNZ WAIT_IDLE

WAIT_SOP:
    // Wait for transition to K-State (Pin 0=1, Pin 1=0 -> Pin value 1)
    LOAD PIN_STATE
    STORE B
    LOADI 3
    AND B
    STORE B
    LOADI 1            // K-State has value 1
    SUB B
    JMPNZ WAIT_SOP

    // SOP Detected!
    // Edge detected at 2450ns. Delay exactly 3 cycles (60ns)
    // to align first sample at 2530ns (exact center of bit 0 [2200..2860]).
    LOADI 0
    STORE B
    LOAD B

SAMPLE_LOOP:
    // Sample bus at center
    LOAD PIN_STATE
    STORE B
    LOADI 3
    AND B
    STORE R2           // R2 = sampled pin value (0, 1, or 2)

    // Check if SE0 (EOP): Pin 0 == 0 and Pin 1 == 0 -> R2 == 0
    LOAD R2
    JMPNZ CHECK_K

    // SE0 detected! Send EOP token (2) to SHARED_2
    LOADI 2
    STORE SHARED_2
    JMP WAIT_IDLE

CHECK_K:
    // Check if K-State (R2 == 1)
    STORE B
    LOADI 1
    SUB B
    JMPNZ SEND_J

SEND_K:
    LOADI 1            // K State
    STORE SHARED_2
    JMP DELAY_BIT

SEND_J:
    LOADI 0            // J State
    STORE SHARED_2
    LOAD B             // 1-cycle NOP to equalize branch timing with SEND_K
    JMP DELAY_BIT

DELAY_BIT:
    // Delay 33 clock cycles to reach next bit center (19 loop cycles + 14 timer cycles)
    LOADI 14
    STORE TIMER_L
WAIT_NEXT_SAMPLE:
    LOAD TIMER_L
    JMPNZ WAIT_NEXT_SAMPLE

    JMP SAMPLE_LOOP
