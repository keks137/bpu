LDI r1 write_char
LDI r2 "H"
STR r1 r2
LDI r2 "e"
STR r1 r2
LDI r2 "l"
STR r1 r2
LDI r2 "l"
STR r1 r2
LDI r2 "o"
STR r1 r2
LDI r2 "!"
STR r1 r2
LDI r1 buffer_chars
STR r1 r2
.loop
jmp .loop
