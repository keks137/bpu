package main

import "core:fmt"
import "core:os"
import "core:strconv"
import "core:strings"

binaryze :: proc() {
	data, err := os.read_entire_file_from_path("output.mc", context.allocator)
	if err != nil {
		fmt.eprintln("failed to read output.mc")
		os.exit(1)
	}
	defer delete(data)

	lines := strings.split_lines(string(data))
	defer delete(lines)

	outf: ^os.File
	outf, err = os.open(
		"output.mcb",
		os.O_WRONLY | os.O_CREATE | os.O_TRUNC,
		perm = os.Permissions_Default_File,
	)
	if err != nil {
		fmt.eprintln("failed to open output.mcb")
		os.exit(1)
	}
	defer os.close(outf)

	for line in lines {
		if len(line) == 0 do continue
		val, _ := strconv.parse_u64_of_base(strings.trim_space(line), 2)
		be16 := u16be(val)
		os.write_ptr(outf, &be16, 2)
	}
}
