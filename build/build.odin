package main
import "base:runtime"
import "core:fmt"
import "core:os"


run_cmd :: proc(cmd: ^[dynamic]string) -> bool {

	desc := os.Process_Desc {
		command = cmd[:],
		stdout  = os.stdout,
		stderr  = os.stderr,
	}
	process, err := os.process_start(desc)
	if err != nil {
		fmt.eprintln("spawn failed:", err)
		return false
	}


	state: os.Process_State
	state, err = os.process_wait(process)
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
