; Prog04 - Check Power of Two
;
; Input:
;   NUM = 1024
;
; Output:
;   RESULT = 1

ENCHANT R3, 0
ENCHANT R0, NUM
SUMMON R1, R0

JUDGE R1, R3
WARPZ SKIP          ; if NUM == 0, branch to store RESULT= 0

MIRROR R2, R1
FALL R2
AND R2, R1
WARPNZ SKIP         ; if (NUM & (NUM-1)) != 0, branch to store RESULT= 0

ENCHANT R0, RESULT

RISE R3             ; RESULT= 1 (NUM is a power of 2)
SEAL R0, R3
FREEZE

SKIP:
SEAL R0, R3         ; Store RESULT= 0
FREEZE


NUM:
DW 1024

RESULT:
DW 0