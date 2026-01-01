; sum = 0
ANDI  0x000        ; R0 = 0
MOVETO R1          ; R1 = sum = 0

; sum += a[0]
LOAD   0x100       ; R0 = a[0]
ADD    R1          ; R0 = R0 + R1
MOVETO R1          ; R1 = sum

; sum += a[1]
LOAD   0x101
ADD    R1
MOVETO R1

; sum += a[2]
LOAD   0x102
ADD    R1
MOVETO R1

; sum += a[3]
LOAD   0x103
ADD    R1
MOVETO R1

; sum += a[4]
LOAD   0x104
ADD    R1
MOVETO R1

; sum += a[5]
LOAD   0x105
ADD    R1
MOVETO R1

; sum += a[6]
LOAD   0x106
ADD    R1
MOVETO R1

; sum += a[7]
LOAD   0x107
ADD    R1
MOVETO R1

; sum += a[8]
LOAD   0x108
ADD    R1
MOVETO R1

; sum += a[9]
LOAD   0x109
ADD    R1
MOVETO R1

; store result
MOVEFROM R1        ; R0 = sum
STORE  0x110       ; M[0x110] = sum

; optional: stop (no HALT in ISA) — infinite loop
JUMP   0x000       ; or jump to itself / a safe address
