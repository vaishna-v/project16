; Prog04 - Parity Check
;
; Input:
;   NUM = 15 ( 0000000000001111 )
;
; Output:
;   RESULT = 0 (even parity) 

ENCHANT R0, NUM
SUMMON R1, R0

ENCHANT R3, 0       ; parity accumulator
ENCHANT R4, 16

LOOP:

ENCHANT R2, 0
SHL R1, 1           ; extract bit from input
WARPC SKIP          ; skip is carry= 0
RISE R2             ; set R2 if carry= 1

SKIP:
XOR R3, R2          ;  accumulate parity (XOR all bits)

FALL R4
WARPNZ LOOP         ; repeat for all 16 bits

ENCHANT R0, RESULT
SEAL R0, R3
FREEZE


NUM:
DW 15

RESULT:
DW 0