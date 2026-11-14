// ==========================================
// Ethernet CPU 4: RX Edge Detector (Manchester)
// Emulates 10BASE-T Manchester decoding on Pin 2 (UIO[2]).
// Syncs to mid-bit data edges, skips clock edges using 3/4 T delay.
// Pushes decoded bits (0 or 1) to SHARED_2 for CPU 5.
// ==========================================

    // Get 3/4 Bit Time Delay from Host RX_FIFO
    LOAD RX_FIFO 
    STORE R7

    // Keep Pin 2 mask (0x04) in R6
    LOADI 4
    STORE R6

    // Initialize Old State on Pin 2 (mask 0x04)
    LOAD PIN_STATE
    STORE B
    LOAD R6
    AND B
    STORE R2           // R2 = Old State

WAIT_EDGE:
    LOAD PIN_STATE
    STORE B
    LOAD R6
    AND B
    STORE R3           // R3 = New sampled state
    
    STORE B
    LOAD R2
    SUB
    JMPNZ EDGE_FOUND
    JMP WAIT_EDGE

EDGE_FOUND:
    // Update Old State
    LOAD R3
    STORE R2

    // Send Bit to CPU 5 via SHARED_2
    // If R3 == 4 (rising transition = Manchester 1), push 1.
    // If R3 == 0 (falling transition = Manchester 0), push 0.
    LOAD R3
    JMPNZ PUSH_ONE

PUSH_ZERO:
    LOADI 0
    STORE SHARED_2
    JMP SKIP_DELAY

PUSH_ONE:
    LOADI 1
    STORE SHARED_2

SKIP_DELAY:
    // Wait 3/4 Bit Time to skip clock edge
    LOAD R7
    STORE TIMER_L
    LOAD TIMER_L

    // Update Old State after delay
    LOAD PIN_STATE
    STORE B
    LOAD R6
    AND B
    STORE R2

    JMP WAIT_EDGE
