package main
main :: proc() {
	if len(os.args) >= 2 {
		switch os.args[1] {


		case "rebuild":
			binaryze()
		case:
			fmt.eprintfln("Unknown argument: %s", os.args[1])
			os.exit(1)
		}

	}

	cmd: [dynamic]string


	append(&cmd, "odin")
	append(&cmd, "build")
	append(&cmd, "vm")
	append(&cmd, "-debug")
	append(&cmd, "-out:bpu")

	if !run_cmd(&cmd) {os.exit(1)}
}

run_cmd :: proc(cmd: ^[dynamic]string) -> (ok: bool) {

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
	if err != nil {return false}
	if state.exit_code != 0 {return false}
	clear_dynamic_array(cmd)

	return true
}


import "base:runtime"
import "core:fmt"
import "core:os"
