package main
import "base:runtime"
import "core:fmt"
import "core:os"
import "core:os/os2"


run_cmd :: proc(cmd: ^[dynamic]string) -> bool {

	desc := os2.Process_Desc {
		command = cmd[:],
		stdout  = os2.stdout,
		stderr  = os2.stderr,
	}
	process, err := os2.process_start(desc)
	if err != nil {
		fmt.eprintln("spawn failed:", err)
		return false
	}


	state: os2.Process_State
	state, err = os2.process_wait(process)
	if state.exit_code != 0 {return false}
	if err != nil {return false}
	clear_dynamic_array(cmd)

	return true
}

main :: proc() {
	if len(os.args) >= 2 {
		binaryze()

	}

	cmd: [dynamic]string


	append(&cmd, "odin")
	append(&cmd, "build")
	append(&cmd, "src")
	append(&cmd, "-debug")
	append(&cmd, "-out:bpu")

	if !run_cmd(&cmd) {os.exit(1)}
}
