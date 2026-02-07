package main

import "core:fmt"
import "core:os"
import "core:os/os2"
import "core:strconv"
import "core:strings"

binaryze :: proc() {
	data, ok := os.read_entire_file("output.mc")
	if !ok {
		fmt.eprintln("failed to read output.mc")
		os.exit(1)
	}
	defer delete(data)

	lines := strings.split_lines(string(data))
	defer delete(lines)

	outf, err := os2.open(
		"output.mcb",
		os2.O_WRONLY | os2.O_CREATE | os2.O_TRUNC,
		perm = os2.Permissions_Default_File,
	)
	if err != nil {
		fmt.eprintln("failed to open output.mcb")
		os.exit(1)
	}
	defer os2.close(outf)

	for line in lines {
		if len(line) == 0 do continue
		val, _ := strconv.parse_u64_of_base(strings.trim_space(line), 2)
		be16 := u16be(val)
		os2.write_ptr(outf, &be16, 2)
	}
}
