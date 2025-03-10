package controls

import "vendor:raylib"

run_keyboard_inputs :: proc() -> Controls {
	left_just_pressed := raylib.IsKeyPressed(raylib.KeyboardKey.LEFT)
	right_just_pressed := raylib.IsKeyPressed(raylib.KeyboardKey.RIGHT)
	up_just_pressed := raylib.IsKeyPressed(raylib.KeyboardKey.UP)
	down_just_pressed := raylib.IsKeyPressed(raylib.KeyboardKey.DOWN)

	result := Controls {
		left_just_pressed  = left_just_pressed,
		right_just_pressed = right_just_pressed,
		up_just_pressed    = up_just_pressed,
		down_just_pressed  = down_just_pressed,
	}

	return result
}
