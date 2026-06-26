; Program for Fibonacci
; Input = 7
; Result should be 13

ENCHANT R0, 1      ; a = F(2) = 1
ENCHANT R1, 1      ; b = F(3) = 1
ENCHANT R2, 5      ; counter = Input - 2 = 5
ENCHANT R4, 0      ; constant 0

LOOP:
    MIRROR R3, R0      ; temp = a
    FUSE R3, R1        ; temp = a + b

    MIRROR R0, R1      ; a = b
    MIRROR R1, R3      ; b = temp

    FALL R2            ; counter--

    JUDGE R2, R4       ; compare counter with 0
    WARPNZ LOOP

; Write final result to memory
ENCHANT R5, RESULT
SEAL R5, R1
FREEZE

RESULT:
DW 0
