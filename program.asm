; Generate first 10 Fibonacci numbers

; R0 = zero
; R1 = a
; R2 = b
; R3 = temp
; R4 = counter
; R5 = one

start:

    ENCHANT R0, 0
    ENCHANT R1, 0
    ENCHANT R2, 1
    ENCHANT R4, 10
    ENCHANT R5, 1

fib_loop:

    MIRROR R3, R1

    FUSE R3, R2

    MIRROR R1, R2

    MIRROR R2, R3

    FALL R4

    JUDGE R4, R0

    WARPNZ fib_loop

    FREEZE