package bpu_asm
main :: proc() {
	in_file := os.args[1]
	file, err := os.read_entire_file(in_file, context.allocator)
	if err != nil {
		fmt.eprintln(in_file, ":", err)
		os.exit(1)
	}
	file_data := strings.to_lower(string(file))
	p := Parser{}
	p.file_data = transmute([]u8)file_data
	p.tok.filename = in_file
	p.tok.data = file_data
	next_rune(&p.tok)
	advance_token(&p)
	parse_file(&p)
	if p.tok.error_count != 0 {os.exit(1)}
	out_file := "output.mcb"
	err = os.write_entire_file(out_file, p.out[:])
	if err != nil {
		fmt.eprintln(out_file, ":", err)
		os.exit(1)
	}
}
write_op :: proc(p: ^Parser, op: []u8) {
	assert(len(op) == 2)
	append_elems(&p.out, ..op)
	p.ip += 1
}
parse_val10 :: proc(p: ^Parser) -> (val: u16) {
	#partial switch p.curr.kind {
	case .Label:
		lbl := advance_token(p)
		ok: bool
		val, ok = p.labels[lbl.text]
		if !ok {
			syntax_error(&p.tok, lbl.pos, "Unknown label: %s", lbl.text)
		}
	case:
		syntax_error(
			&p.tok,
			p.curr.pos,
			"wanted a 10 bit value, got '%s' of kind %s",
			p.curr.text,
			p.curr.kind,
		)
	}
	return
}
Cond :: enum u8 {
	EQ,
	NE,
	GE,
	LT,
}
Op10 :: bit_field [2]u8 {
	op:   Ops  | 4,
	cond: Cond | 2,
	val:  u16  | 10,
}
is_reg :: proc(kind: TokenKind) -> (val: u8, ok: bool) {
	if kind >= .R0 && kind <= .R15 {
		ok = true
		val = u8(int(kind) - int(TokenKind.R0))
	}
	return
}
parse_val8 :: proc(p: ^Parser) -> (val: u8) {
	#partial switch p.curr.kind {
	case .Number:
		num := advance_token(p)
		val_int, ok := strconv.parse_int(num.text)
		if ok {
			val = u8(val_int)
		} else {
			syntax_error(&p.tok, num.pos, "not a valid number: %s", num.text)
		}
	case:
		syntax_error(
			&p.tok,
			p.curr.pos,
			"wanted an 8 bit value, got '%s' of kind %s",
			p.curr.text,
			p.curr.kind,
		)
	}
	return
}
parse_stmt :: proc(p: ^Parser) {
	#partial switch p.curr.kind {
	case .Ldi:
		ldi := advance_token(p)
		reg := advance_token(p)
		if regval, ok := is_reg(reg.kind); ok {
			num := parse_val8(p)
			op := [2]u8{}
			op[0] |= u8(Ops.LDI) << 4
			op[0] |= regval
			op[1] |= num

		} else {
			syntax_error(&p.tok, p.curr.pos, "expected a register, got '%s'", reg.text)
		}

	case .Label:
		lbl := advance_token(p)
		p.labels[lbl.text] = p.ip
	case .Nop:
		advance_token(p)
		write_op(p, {0, 0})
	case .Str:
		str := advance_token(p)
		reg := advance_token(p)
		if regval, ok := is_reg(reg.kind); ok {
			num := parse_val8(p)
			op := [2]u8{}
			op[0] |= u8(Ops.LDI) << 4
			op[0] |= regval
			op[1] |= num

		} else {
			syntax_error(&p.tok, p.curr.pos, "expected a register, got '%s'", reg.text)
		}

	case .Hlt:
		advance_token(p)
		write_op(p, {u8(Ops.HLT) << 4, 0})
	case .Jmp:
		jmp_instr := advance_token(p)
		val := parse_val10(p)
		op := [2]u8{}
		op[0] |= u8(Ops.JMP) << 4
		op[0] |= u8((val >> 8) & 0b11)
		op[1] |= u8(val)
		write_op(p, op[:])
	case:
		syntax_error(&p.tok, p.curr.pos, "unexpected '%s' of kind %s", p.curr.text, p.curr.kind)
		advance_token(p)
	}
	if p.curr.kind == .Semicolon {
		advance_token(p)
	} else {
		syntax_error(
			&p.tok,
			p.curr.pos,
			"expected semicolon, have '%s' of kind %s",
			p.curr.text,
			p.curr.kind,
		)
	}
}
parse_file :: proc(p: ^Parser) {
	for {
		if p.curr.kind == .EOF {break}
		parse_stmt(p)
	}
}
advance_token :: proc(p: ^Parser) -> Token {
	p.prev = p.curr
	p.curr = get_token(&p.tok)
	return p.prev
}
Pos :: struct {
	offset: int,
	line:   int,
	column: int,
}
Ops :: enum u8 {
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
TokenKind :: enum {
	Invalid,
	EOF,
	Ident,
	Label,
	Number,
	Char,
	Semicolon,
	//Keywords:
	Nop,
	Hlt,
	Add,
	Sub,
	Nor,
	And,
	Xor,
	Rsh,
	Ldi,
	Adi,
	Jmp,
	Brh,
	Cal,
	Ret,
	Lod,
	Str,
	Cmp,
	Mov,
	Lsh,
	Inc,
	Dec,
	Not,
	Neg,
	R0,
	R1,
	R2,
	R3,
	R4,
	R5,
	R6,
	R7,
	R8,
	R9,
	R10,
	R11,
	R12,
	R13,
	R14,
	R15,
	Define,
}
token_names := [TokenKind]string {
	.Invalid   = "<invalid>",
	.EOF       = "<EOF>",
	.Ident     = "<ident>",
	.Number    = "<number>",
	.Label     = ".<label>",
	.Char      = "\"<char>\"",
	.Semicolon = ";",
	.Nop       = "nop",
	.Hlt       = "hlt",
	.Add       = "add",
	.Sub       = "sub",
	.Nor       = "nor",
	.And       = "and",
	.Xor       = "xor",
	.Rsh       = "rsh",
	.Ldi       = "ldi",
	.Adi       = "adi",
	.Jmp       = "jmp",
	.Brh       = "brh",
	.Cal       = "cal",
	.Ret       = "ret",
	.Lod       = "lod",
	.Str       = "str",
	.Cmp       = "cmp",
	.Mov       = "mov",
	.Lsh       = "lsh",
	.Inc       = "inc",
	.Dec       = "dec",
	.Not       = "not",
	.Neg       = "neg",
	.R0        = "r0",
	.R1        = "r1",
	.R2        = "r2",
	.R3        = "r3",
	.R4        = "r4",
	.R5        = "r5",
	.R6        = "r6",
	.R7        = "r7",
	.R8        = "r8",
	.R9        = "r9",
	.R10       = "r10",
	.R11       = "r11",
	.R12       = "r12",
	.R13       = "r13",
	.R14       = "r14",
	.R15       = "r15",
	.Define    = "define",
}
Token :: struct {
	using pos: Pos,
	kind:      TokenKind,
	text:      string,
}
Tokenizer :: struct {
	using pos:        Pos,
	data:             string,
	filename:         string,
	ch:               rune, // current rune/character
	w:                int, // current rune width in bytes
	curr_line_offset: int,
	insert_semicolon: bool,
	error_count:      int,
}
Parser :: struct {
	tok:       Tokenizer,
	file_data: []byte,
	prev:      Token,
	curr:      Token,
	out:       [dynamic]u8,
	labels:    map[string]u16,
	ip:        u16,
}
next_rune :: proc(t: ^Tokenizer) -> rune {
	if t.offset < len(t.data) {
		t.offset += t.w
		t.ch, t.w = utf8.decode_rune_in_string(t.data[t.offset:])
		t.pos.column = t.offset - t.curr_line_offset
	}

	if t.offset >= len(t.data) {
		t.ch = utf8.RUNE_EOF
		t.w = 1
	}
	return t.ch
}
get_token :: proc(t: ^Tokenizer) -> (token: Token) {
	skip_whitespace :: proc(t: ^Tokenizer) -> rune {
		for t.offset < len(t.data) {
			switch t.ch {
			case ' ', '\t', '\r', '\f', '\v':
				next_rune(t)
			case '\n':
				if !t.insert_semicolon {
					t.line += 1
					t.curr_line_offset = t.offset
					t.pos.column = 1
					next_rune(t)
					break
				}
				return t.ch
			case:
				return t.ch
			}
		}
		return t.ch
	}

	skip_hex_digits :: proc(t: ^Tokenizer) {
		for t.offset < len(t.data) {
			switch t.ch {
			case '0' ..= '9', 'a' ..= 'f', 'A' ..= 'F':
				next_rune(t)
			case:
				return
			}
		}
	}

	skip_digits :: proc(t: ^Tokenizer) {
		for t.offset < len(t.data) {
			switch t.ch {
			case '0' ..= '9':
				next_rune(t)
			case:
				return
			}
		}
	}

	scan_escape :: proc(t: ^Tokenizer) {
		// TODO(bill): scan_escape
	}


	skip_whitespace(t)

	token.pos = t.pos
	token.kind = .Invalid

	ch := t.ch
	next_rune(t)

	switch ch {
	case utf8.RUNE_ERROR:
		syntax_error(t, token.pos, "illegal character found: %c", ch)
	// illegal character

	case utf8.RUNE_EOF, '\x00':
		token.kind = .EOF
		if t.insert_semicolon {
			t.insert_semicolon = false
			token.kind = .Semicolon
			token.text = "\n"
			return
		}
	case '\n':
		token.kind = .Semicolon
		token.text = "\n"
		t.insert_semicolon = false
		t.line += 1
		t.curr_line_offset = t.offset
		t.pos.column = 1

		return
	case '/':
		if t.ch == '/' {
			for t.offset < len(t.data) {
				if t.ch == '\n' {
					return get_token(t)
				}
				next_rune(t)
			}
		} else if t.ch == '*' {
			for t.offset < len(t.data) {
				next_rune(t)
				if t.ch == '\n' {
					t.pos.line += 1
					t.curr_line_offset = t.pos.offset
				}
				if t.ch == '*' {
					next_rune(t)
					if t.ch == '/' {
						next_rune(t)
						return get_token(t)
					}
				}
			}
			syntax_error(t, token.pos, "non-closing block comment")
			token.kind = .EOF

		}
	case '.':
		token.kind = .Label
		label_loop: for t.offset < len(t.data) {
			switch t.ch {
			case 'A' ..= 'Z', 'a' ..= 'z', '_':
				next_rune(t)
			case '0' ..= '9':
				next_rune(t)
			case:
				break label_loop
			}
		}

	case '0' ..= '9', '-':
		token.kind = .Number
		if ch == '0' && t.ch == 'x' { 	// hexadecimal number
			next_rune(t)
			skip_hex_digits(t)
			break
		}
		skip_digits(t)


	case '"':
		token.kind = .Char
		if t.ch != '"' {
			syntax_error(t, token.pos, "expected '\"'")
		} else {
			next_rune(t)
		}
	case 'A' ..= 'Z', 'a' ..= 'z', '_':
		token.kind = .Ident
		ident_loop: for t.offset < len(t.data) {
			switch t.ch {
			case 'A' ..= 'Z', 'a' ..= 'z', '_':
				next_rune(t)
			case '0' ..= '9':
				next_rune(t)
			case:
				break ident_loop
			}
		}

		str := t.data[token.offset:t.offset]
		for keyword in TokenKind.Nop ..< TokenKind(len(TokenKind)) {
			if token_names[keyword] == str {
				token.kind = keyword
				break
			}
		}
	case:
		syntax_error(t, token.pos, "invalid character found: %q", ch)
	}
	#partial switch token.kind {
	case .Number, .Label, .Hlt, .Nop:
		t.insert_semicolon = true
	case:
		t.insert_semicolon = false
	}
	token.text = t.data[token.offset:t.offset]
	return
}
syntax_error :: proc(t: ^Tokenizer, pos: Pos, format: string, args: ..any) {
	fmt.eprintf("%s:%d:%d Syntax Error: ", t.filename, pos.line, pos.column)
	fmt.eprintfln(format, args = args)
	t.error_count += 1
}
import "core:fmt"
import "core:os"
import "core:strconv"
import "core:strings"
import "core:unicode/utf8"
