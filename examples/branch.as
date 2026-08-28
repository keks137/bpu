LDI r4 5
.for
LDI r1 247
LDI r2 29 // '?'
STR r1 r2 0
DEC r4
BRH notzero .for
LDI r1 248
STR r1 r2 0
.loop
jmp .loop

