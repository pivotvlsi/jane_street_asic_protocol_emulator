// ==========================================
// USB 1.1 Low-Speed RX: CPU 5 NRZI Decoder & Bit Unstuffer
// Reads sampled state from SHARED_2 (0=J, 1=K, 2=EOP).
// - NRZI Decode: Toggle = 0, Same = 1.
// - Bit Unstuff: If 6 consecutive 1s occur, the next 0 is stuffed and dropped.
// Pushes clean payload bits to SHARED_3:
//   0 = Bit 0
//   1 = Bit 1
//   2 = EOP
// ==========================================

    // Initialize previous state to J-State (0)
    LOADI 0
    STORE R2           // R2 = previous state (0=J, 1=K)
    LOADI 0
    STORE R3           // R3 = consecutive 1s counter

WAIT_INPUT:
    LOAD SHARED_2      // Blocks until CPU 4 writes to SHARED_2
    STORE B            // B = current state

    // Check if EOP (value 2)
    LOADI 2
    SUB B
    JMPNZ PROCESS_DATA

    // It is EOP: Reset counter and forward EOP token to CPU 0
    LOADI 0
    STORE R2           // Reset prev state to J
    LOADI 0
    STORE R3           // Reset consecutive 1s
    LOADI 2
    STORE SHARED_3
    JMP WAIT_INPUT

PROCESS_DATA:
    // NRZI Check: Compare current state (B) with previous state (R2)
    LOAD R2
    SUB B
    JMPNZ STATE_CHANGED

STATE_SAME:
    // State is the same -> Logical 1
    // Update previous state (R2 = B)
    LOAD B
    STORE R2

    // Consecutive 1s counter++
    LOADI 1
    STORE B
    LOAD R3
    ADD B
    STORE R3

    // Push Logical 1 to SHARED_3
    LOADI 1
    STORE SHARED_3
    JMP WAIT_INPUT

STATE_CHANGED:
    // State changed -> Logical 0 (or stuffed 0)
    // Update previous state (R2 = B)
    LOAD B
    STORE R2

    // Check if consecutive 1s == 6 (Stuffed Bit Check)
    LOAD R3
    STORE B
    LOADI 6
    SUB B
    JMPNZ REGULAR_ZERO

STUFFED_ZERO:
    // Counter reached 6 -> This 0 is a stuffed bit!
    // Drop this bit (do NOT push to SHARED_3) and reset counter
    LOADI 0
    STORE R3
    JMP WAIT_INPUT

REGULAR_ZERO:
    // Regular 0: reset counter and push 0 to SHARED_3
    LOADI 0
    STORE R3
    LOADI 0
    STORE SHARED_3
    JMP WAIT_INPUT
