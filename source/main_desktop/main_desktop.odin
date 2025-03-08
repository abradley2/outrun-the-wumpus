package main_desktop

import game ".."
import "core:log"
import "core:mem"
import "core:os"
import "core:path/filepath"

main :: proc() {
	// Set working dir to dir of executable.
	exe_path := os.args[0]
	exe_dir := filepath.dir(string(exe_path), context.temp_allocator)
	os.set_current_directory(exe_dir)

	context.logger = log.create_console_logger()

	base_allocator := context.allocator
	tracking_allocator := new(mem.Tracking_Allocator)
	mem.tracking_allocator_init(tracking_allocator, base_allocator)
	context.allocator = mem.tracking_allocator(tracking_allocator)

	game.init()

	for game.should_run() {
		game.update()
	}

	game.shutdown()
}
