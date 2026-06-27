; Prog04 - Reverse Bits
;
; Input:
;   NUM = 13 ( 0000000000001101 )
;
; Output:
;   RESULT = 45056 ( 1011000000000000 )

ENCHANT R0, NUM
SUMMON R1, R0

ENCHANT R2, 16
ENCHANT R3, 0

LOOP:

ENCHANT R4, 1       ; mask= 1
AND R4, R1          ; extract current LSB of input

SHL R3, 1           ; make space for new bit
OR R3, R4           ; insert extracted bit

SHR R1, 1           ; move to next bit of NUM

FALL R2
WARPNZ LOOP         ; repeat for all 16 bits

ENCHANT R0, RESULT
SEAL R0, R3
FREEZE


NUM:
DW 13

RESULT:
DW 0