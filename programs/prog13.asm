; Prog13 - Least Common Multiple (LCM)
; Input:
;   NUM1 = 12
;   NUM2 = 15
; Output:
;   RESULT = 60

; Load inputs from memory
ENCHANT R4, NUM1
SUMMON R0, R4        ; R0 = A = 12

ENCHANT R4, NUM2
SUMMON R1, R4        ; R1 = B = 15

MIRROR R2, R0        ; R2 = M1 = 12
MIRROR R3, R1        ; R3 = M2 = 15

LCM_LOOP:
JUDGE R2, R3
WARPZ DONE           ; If M1 == M2, jump to DONE

WARPC M1_LESS        ; If M1 < M2 (Carry flag set), jump to M1_LESS

; Else M1 > M2: M2 = M2 + B
FUSE R3, R1
WARP LCM_LOOP

M1_LESS:
; M1 = M1 + A
FUSE R2, R0
WARP LCM_LOOP

DONE:
ENCHANT R4, RESULT
SEAL R4, R2          ; Store M1 (LCM) to RESULT
FREEZE

; --- Data Segment ---
NUM1:
DW 12

NUM2:
DW 15

RESULT:
DW 0
