; Prog12 - Greatest Common Divisor (GCD)
; Input:
;   NUM1 = 12
;   NUM2 = 15
; Output:
;   RESULT = 3

; Load NUM1 and NUM2 from memory
ENCHANT R2, NUM1
SUMMON R0, R2        ; R0 = NUM1 = 12

ENCHANT R2, NUM2
SUMMON R1, R2        ; R1 = NUM2 = 15

GCD_LOOP:
; Compare R0 and R1
JUDGE R0, R1
WARPZ DONE           ; If R0 == R1, we are done!

WARPC B_GREATER      ; If R0 < R1 (Carry flag set), jump to B_GREATER

; Else R0 > R1, so R0 = R0 - R1
DRAIN R0, R1
WARP GCD_LOOP

B_GREATER:
; R1 = R1 - R0
DRAIN R1, R0
WARP GCD_LOOP

DONE:
; Store GCD result (R0) into RESULT memory address
ENCHANT R2, RESULT
SEAL R2, R0
FREEZE

; --- Data Segment ---
NUM1:
DW 12

NUM2:
DW 15

RESULT:
DW 0
