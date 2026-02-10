define base_devices_pointer 248
define px -8
define py -7
define draw_p -6
define clear_p -5
define load_p -4
define push_screen -3
define clear_screen -2
define put_char -1
define push_chars 0
define clear_chars 1
define show_num 2
define clear_num 3
define signed 4
define unsigned 5
define RNJesus 6
define controller_inp 7


LDI r15 base_devices_pointer


LDI r1 "H"
STR r15 r1 put_char
LDI r1 "I"
STR r15 r1 put_char
STR r15 r0 push_chars

LDI r1 1
STR r15 r1 px
STR r15 r1 py

STR r15 r0 draw_p

STR r15 r0 push_screen
