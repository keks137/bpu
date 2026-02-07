.redo
// clear chars
LDI r1 249
STR r1 r1 0
LDI r2 0



LDI r4 3
.loop

//LDI r7 255
//.wait3
//LDI r6 255
//.wait2
//LDI r5 255
.wait
ADI r5 -1
BRH notzero .wait
//ADI r6 -1
//BRH notzero .wait2
//ADI r7 -1
//BRH notzero .wait3




LDI r3 10
.printloop
LDI r1 247
STR r1 r2 0
ADI r2 1
ADI r3 -1
BRH notzero .printloop
// print
LDI r1 248
STR r1 r2 0



ADI r4 -1
BRH notzero .loop


JMP .redo

HLT
