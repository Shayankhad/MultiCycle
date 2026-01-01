; Array:   ram[0x0100 .. 0x0109] = 1..10
; Result:  ram[0x0110]
; Program: starts at ram[0x0000]

; ====== Registers ======
; R0 = accumulator (defined by ISA)
; R1 = running sum

; sum = 0
ANDI   0x000        ; R0 = 0
MOVETO R1           ; R1 = 0

; sum += a[0..9]  (array stored in RAM 0x0100..0x0109)
LOAD   0x0100       ; R0 = a[0]
ADD    R1           ; R0 = R0 + R1
MOVETO R1           ; R1 = sum

LOAD   0x0101
ADD    R1
MOVETO R1

LOAD   0x0102
ADD    R1
MOVETO R1

LOAD   0x0103
ADD    R1
MOVETO R1

LOAD   0x0104
ADD    R1
MOVETO R1

LOAD   0x0105
ADD    R1
MOVETO R1

LOAD   0x0106
ADD    R1
MOVETO R1

LOAD   0x0107
ADD    R1
MOVETO R1

LOAD   0x0108
ADD    R1
MOVETO R1

LOAD   0x0109
ADD    R1
MOVETO R1

; store result
MOVEFROM R1         ; R0 = sum
STORE  0x0110       ; M[0x0110] = sum

; no HALT instruction -> loop forever at END
END:
JUMP   END          ; infinite loop
