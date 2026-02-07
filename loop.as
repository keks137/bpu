  LDI r2 255
  LDI r3 1
.symbola
  LDI r4 255
.symbolb
  LDI r5 255
.symbolc
  SUB r5 r3 r5
  BRH notzero .symbolc

  SUB r4 r3 r4
  BRH notzero .symbolb

  SUB r2 r3 r2
  BRH notzero .symbola

  HLT
