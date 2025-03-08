package component

import "vendor:raylib"

Movement_Command :: struct {
	target: raylib.Vector3,
	speed:  f32,
}
