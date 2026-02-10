package main

import "core:fmt"
import "core:mem"
import "core:os"
import "core:sync"
import "core:thread"
import rl "vendor:raylib"


ops :: enum {
	NOP = 0,
	HLT = 1,
	ADD,
	SUB,
	NOR,
	AND,
	XOR,
	RSH,
	LDI,
	ADI,
	JMP,
	BRH,
	CAL,
	RET,
	LOD,
	STR,
}

get_args_three_reg :: #force_inline proc(data: []u8) -> (reg_a: u8, reg_b: u8, reg_c: u8) {
	// fmt.printfln("%x", data)
	reg_a = data[0] & 0x0F
	reg_b = (data[1] & 0xF0) >> 4
	reg_c = data[1] & 0x0F
	return
}

instr_add :: #force_inline proc(code: ^Code, reg_a: u8, reg_b: u8, reg_c: u8) {
	regs: []u8 = code.reg[:]
	// fmt.printfln("r%i + r%i -> r%i", reg_a, reg_b, reg_c)
	res := regs[reg_a] + regs[reg_b]
	code.flags.Z = res == 0
	code.flags.C = cast(i8)res < 0

	regs[reg_c] = res
	// fmt.printfln("%i + %i = %i", regs[reg_a], regs[reg_b], res)

}
instr_sub :: #force_inline proc(code: ^Code, reg_a: u8, reg_b: u8, reg_c: u8) {
	regs: []u8 = code.reg[:]
	// fmt.printfln("r%i - r%i -> r%i", reg_a, reg_b, reg_c)
	res := regs[reg_a] - regs[reg_b]
	code.flags.Z = res == 0
	code.flags.C = cast(i8)res < 0

	regs[reg_c] = res
	// fmt.printfln("%i - %i = %i", regs[reg_a], regs[reg_b], res)

}

get_args_imm :: #force_inline proc(data: []u8) -> (reg: u8, imm: u8) {
	reg = data[0] & 0x0F
	imm = data[1]
	return
}

instr_ldi :: #force_inline proc(regs: []u8, reg: u8, imm: u8) {
	// fmt.printfln("%i -> r%i", imm, reg)
	regs[reg] = imm
}
instr_adi :: #force_inline proc(code: ^Code, regs: []u8, reg: u8, imm: u8) {
	res := regs[reg] + imm
	code.flags.Z = res == 0
	code.flags.C = cast(i8)res < 0
	regs[reg] = res

}

instr_jmp :: #force_inline proc(code: ^Code, data: []u8) {
	addr: u16 = (((cast(u16)data[0]) & 0x03) << 8) | cast(u16)data[1]
	code.pc = addr - 1
}


push_char_buffer :: proc(char_buffer: []u8, display_buffer: []u8) {
	for char, i in char_buffer {
		switch char {
		case 0:
			{
				display_buffer[i] = ' '

			}

		case 1 ..< 26:
			{
				display_buffer[i] = char + 64
			}

		case 27:
			display_buffer[i] = '.'
		case 28:
			display_buffer[i] = '!'
		case 29:
			display_buffer[i] = '?'

		}
	}
}

instr_str :: proc(code: ^Code, reg_a: u8, reg_b: u8, pseudo_reg_c: u8) {
	offset := cast(i16)(pseudo_reg_c ~ 8) - 8
	index := ((cast(i16)code.reg[reg_a]) + cast(i16)offset)


	// fmt.printfln("Mem[%i + %i] <- %i", code.reg[reg_a], offset, code.reg[reg_b])
	// fmt.printfln("index: %i, reg_a: %i", index, code.reg[reg_a])
	write_char :: 247
	buffer_chars :: 248
	clear_chars :: 249
	screen_x :: 240
	screen_y :: 241
	draw_pixel :: 242
	clear_pixel :: 243
	buffer_screen :: 245
	clear_screen :: 246
	switch index {
	case write_char:
		{

			code.char_buffer[code.char_buffer_wp] = code.reg[reg_b]
			code.char_buffer_wp += 1
			code.char_buffer_wp = code.char_buffer_wp % len(code.char_buffer)
		}
	case buffer_chars:
		{
			push_char_buffer(code.char_buffer, code.print_buffer)
		}
	case clear_chars:
		{
			code.char_buffer_wp = 0
			mem.zero_slice(code.char_buffer)
		}
	case buffer_screen:
		{
			code.screen = code.screen_buffer
		}
	case draw_pixel:
		{
			x := code.memory[screen_x]
			y := code.memory[screen_y]
			screen_set_pixel(code.screen_buffer, cast(u32)x, cast(u32)y)
		}
	case clear_pixel:
		{
			x := code.memory[screen_x]
			y := code.memory[screen_y]
			screen_clear_pixel(code.screen_buffer, cast(u32)x, cast(u32)y)
		}
	case clear_screen:
		{
			mem.zero_slice(code.screen_buffer)
		}

	case:
		code.memory[index] = code.reg[reg_b]

	}


}

branches :: enum {
	EQ, //Equal (Z==1)
	NE, //Not Equal (Z==0)
	GE, //Greater Than or Equal (C==1)
	LT, //Less Than (C==0)
}
instr_brh :: #force_inline proc(code: ^Code, data: []u8) {
	cond := cast(branches)(((data[0]) & 0b1100) >> 2)
	addr: u16 = (((cast(u16)data[0]) & 0x03) << 8) | cast(u16)data[1]

	// fmt.printfln("%u", addr)

	switch cond {
	case .EQ:
		{if (code.flags.Z) {code.pc = addr - 1}}
	case .NE:
		{if (code.flags.Z == false) {code.pc = addr - 1}}
	case .GE:
		{if (code.flags.C) {code.pc = addr - 1}}
	case .LT:
		{if (code.flags.C == false) {code.pc = addr - 1}}
	}

}

process_instr :: proc(code: ^Code) -> bool {
	res := true
	data: []u8 = code.data[code.pc * 2:][:2]
	instr := cast(ops)((data[0] & 0xF0) >> 4)
	#partial switch instr {
	case .SUB:
		{instr_sub(code, get_args_three_reg(data))}
	case .ADD:
		{instr_add(code, get_args_three_reg(data))}
	case .STR:
		{instr_str(code, get_args_three_reg(data))}
	case .LDI:
		{instr_ldi(code.reg[:], get_args_imm(data))}
	case .ADI:
		{instr_adi(code, code.reg[:], get_args_imm(data))}
	case .HLT:
		{
			code.halted = true
			return false
		}
	case .JMP:
		{instr_jmp(code, data)}


	case .BRH:
		{instr_brh(code, data)}
	case:
		fmt.printfln("%s not implemented", instr)
		os.exit(1)
	}


	code.pc += 1
	return res
}

update_state :: proc(code: ^Code) {
	code.reg[0] = 0
}
process_code :: proc(code: ^Code) -> bool {
	if code.pc * 2 >= cast(u16)len(code.data) {return false}
	update_state(code)


	if !process_instr(code) {return false}
	return true
}


Buttons :: bit_field u8 {
	start:  bool | 1,
	select: bool | 1,
	a:      bool | 1,
	b:      bool | 1,
	up:     bool | 1,
	right:  bool | 1,
	down:   bool | 1,
	left:   bool | 1,
}


Code :: struct {
	halted:         bool,
	data:           []u8,
	memory:         []u8,
	char_buffer:    []u8,
	print_buffer:   []u8,
	char_buffer_wp: int,
	pc:             u16,
	reg:            [16]u8,
	flags:          bit_field u8 {
		Z: bool | 1,
		C: bool | 1,
	},
	screen_buffer:  []u8,
	screen:         []u8,
	buttons:        Buttons,
	stack:          []u16,
	stack_top:      u16,
}


emu_main :: proc(data: rawptr) {
	code := cast(^Code)data

	for !code.halted {
		process_code(code)
	}
}


load_and_run_code :: proc(path: string, code: ^Code, thread_handle: ^^thread.Thread) {
	err: os.Error
	code.data, err = os.read_entire_file_or_err(path)
	if err != nil {
		help := ""
		if err == .ENOENT {
			if path == "output.mcb" {
				help = "\nPlease supply a file"
			}
		}
		fmt.eprintfln("Error: %s file couldn't be opened: %s %s", err, path, help)
		os.exit(1)
	}
	thread_handle^ = thread.create_and_start_with_data(code, emu_main)
}


lamps_x: u32 : 32
lamps_y: u32 : 32


screen_set_pixel :: proc(screen: []u8, x: u32, y: u32) {
	idx := y * lamps_x + x
	screen[idx >> 3] |= 1 << (idx & 7)
}

screen_clear_pixel :: proc(screen: []u8, x: u32, y: u32) {
	idx := y * lamps_x + x
	screen[idx >> 3] &= ~(1 << (idx & 7))
}

get_pixel :: proc(screen: []u8, x: u32, y: u32) -> u8 {
	index: u32 = x + lamps_x * y
	return screen[index >> 3] >> (index & 7) & 1

}
draw_lamps :: proc(code: ^Code, width: u32, height: u32) {
	lampboard_width := width // - width / 10
	lampboard_height := height - height / 10

	lamp_size: u32
	{
		lamp_width: u32 = lampboard_width / lamps_x
		lamp_height: u32 = lampboard_height / lamps_y
		lamp_size = min(lamp_width, lamp_height)

	}

	lampboard_width = lamp_size * lamps_x
	lampboard_height = lamp_size * lamps_y


	for y in 0 ..< lamps_y {
		for x in 0 ..< lamps_x {
			is_on := get_pixel(code.screen, x, y)
			rl.DrawRectangle(
				cast(i32)(x * lamp_size),
				cast(i32)(y * lamp_size),
				cast(i32)lamp_size,
				cast(i32)lamp_size,
				is_on != 0 ? rl.YELLOW : rl.BLACK,
			)
		}}


}

main :: proc() {
	code: Code
	code.memory = make([]u8, 256)
	code.char_buffer = make([]u8, 10)
	code.print_buffer = make([]u8, 11)
	code.screen = make([]u8, 128)
	code.screen_buffer = make([]u8, 128)
	code.stack = make([]u16, 16)

	file: string
	if (len(os.args) < 2) {
		file = "output.mcb"
	} else {
		file = os.args[1]
	}

	emu_thread: ^thread.Thread
	load_and_run_code(file, &code, &emu_thread)


	rl.SetConfigFlags({rl.ConfigFlag.VSYNC_HINT, .WINDOW_RESIZABLE})
	width: i32 = 800
	height: i32 = 450
	rl.InitWindow(width, height, "bpu")

	for !rl.WindowShouldClose() {
		width = rl.GetScreenWidth()
		height = rl.GetScreenHeight()


		if (rl.IsKeyPressed(.R)) {
			code.pc = 0
			code.halted = true
			thread.join(emu_thread)
			code.halted = false
			load_and_run_code(file, &code, &emu_thread)


		}
		if (rl.IsKeyPressed(.UP)) {
			code.buttons.up = true
		}


		// fmt.printf("%s\n", code.print_buffer)
		rl.BeginDrawing()
		if !code.halted {
			rl.ClearBackground(rl.DARKPURPLE)
		} else {
			rl.ClearBackground(rl.RED)
		}


		rl.DrawText(
			cstring(raw_data(code.print_buffer)),
			0,
			height - height / 10,
			height / 10,
			rl.RAYWHITE,
		)
		draw_lamps(&code, cast(u32)width, cast(u32)height)
		rl.EndDrawing()
	}

	code.halted = true
	thread.join(emu_thread)
}
