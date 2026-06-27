; Prog11 - Prime Number Check for Two Numbers
;
; Input:
;   NUM1 = 6
;   NUM2 = 3
;
; Output:
;   RESULT1 = 0 (6 is composite)
;   RESULT2 = 1 (3 is prime)

; --- Main Program ---
ENCHANT R0, NUM1
SUMMON R1, R0       ; R1 = NUM1 = 6
CALL CHECK_PRIME
ENCHANT R0, RESULT1
SEAL R0, R4         ; Store RESULT1

ENCHANT R0, NUM2
SUMMON R1, R0       ; R1 = NUM2 = 3
CALL CHECK_PRIME
ENCHANT R0, RESULT2
SEAL R0, R4         ; Store RESULT2

FREEZE


; --- Subroutine: CHECK_PRIME ---
; Input:  R1 = N
; Output: R4 = 1 (prime) or 0 (not prime)
CHECK_PRIME:
ENCHANT R3, 0       ; R3 = Constant 0
ENCHANT R4, 1       ; R4 = Constant 1 (Default: Prime)

; If N <= 1, it is not prime
JUDGE R1, R4
WARPZ COMPOSITE     ; If N == 1, jump to COMPOSITE
WARPC COMPOSITE     ; If N < 1, jump to COMPOSITE

; Start divisor I at 2
ENCHANT R2, 2       ; R2 = I = 2

DIVISOR_LOOP:
; If I == N, then divisor loop is finished, N is prime (R4 is already 1)
JUDGE R2, R1
WARPZ RETURN_SUB

; Check if N (R1) is divisible by I (R2)
; Copy N to R5 (TEMP)
MIRROR R5, R1

SUB_LOOP:
; If TEMP < I, subtraction is done (Carry flag set)
JUDGE R5, R2
WARPC CHECK_REMAINDER

; TEMP = TEMP - I
DRAIN R5, R2
WARP SUB_LOOP

CHECK_REMAINDER:
; If remainder (R5) == 0, then N is composite
JUDGE R5, R3
WARPZ COMPOSITE

; Else, increment I and check next divisor
RISE R2
WARP DIVISOR_LOOP

COMPOSITE:
ENCHANT R4, 0       ; Set R4 = 0 (Not Prime)

RETURN_SUB:
RET                 ; Return to caller


; --- Data Segment ---
NUM1:
DW 6

NUM2:
DW 3

RESULT1:
DW 0

RESULT2:
DW 0

