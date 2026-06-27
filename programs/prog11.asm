; Prog11 - Prime Number Check for Two Numbers
; Implemented using a loop over an array of inputs for simplicity and code reuse.

; Initialize pointers and loop counter
ENCHANT R6, NUM1         ; R6 points to the input array
ENCHANT R7, RESULT1      ; R7 points to the output array
ENCHANT R0, 2            ; R0 = loop counter (we have 2 numbers to check)

MAIN_LOOP:
; Load the current number
SUMMON R1, R6            ; R1 = number to check

; Setup prime check constants/defaults
ENCHANT R3, 0            ; R3 = Constant 0
ENCHANT R4, 1            ; R4 = Constant 1 (Default: Prime)

; If N <= 1, it is not prime
JUDGE R1, R4
WARPZ COMPOSITE          ; If N == 1, jump to COMPOSITE
WARPC COMPOSITE          ; If N < 1, jump to COMPOSITE

; Start divisor I at 2
ENCHANT R2, 2            ; R2 = I = 2

DIVISOR_LOOP:
; If I == N, divisor loop is finished, N is prime (R4 remains 1)
JUDGE R2, R1
WARPZ STORE_RESULT

; Check if N (R1) is divisible by I (R2)
MIRROR R5, R1            ; R5 = TEMP = N

SUB_LOOP:
; If TEMP < I, subtraction is done (Carry flag set)
JUDGE R5, R2
WARPC CHECK_REMAINDER
DRAIN R5, R2            ; TEMP = TEMP - I
WARP SUB_LOOP

CHECK_REMAINDER:
; If remainder (R5) == 0, then N is composite
JUDGE R5, R3
WARPZ COMPOSITE

; Else, increment I and check next divisor
RISE R2
WARP DIVISOR_LOOP

COMPOSITE:
ENCHANT R4, 0            ; Set R4 = 0 (Not Prime)

STORE_RESULT:
; Store the result for the current number
SEAL R7, R4

; Move to the next number
RISE R6                  ; Increment input pointer
RISE R7                  ; Increment output pointer

; Decrement loop counter
FALL R0
ENCHANT R5, 0            ; Compare R0 with 0
JUDGE R0, R5
WARPNZ MAIN_LOOP         ; Loop if counter R0 != 0

FREEZE


; --- Data Segment ---
NUM1:
DW 6

NUM2:
DW 3

RESULT1:
DW 0

RESULT2:
DW 0


