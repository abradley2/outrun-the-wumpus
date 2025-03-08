package system

import "../component"
import "vendor:raylib"

run_camera_follow_system :: proc(
	camera: ^raylib.Camera2D,
	is_player_components: []Maybe(component.Is_Player),
	position_components: []Maybe(component.Position),
) {
	for entity_id in 0 ..< len(is_player_components) {
		if is_player_components[entity_id] == nil {
			continue
		}

		position := (&position_components[entity_id].?) or_continue

		next_target := raylib.Vector2 {
			position.x - 240 + 32,
			position.y - (f32(raylib.GetScreenHeight()) / camera.zoom / 2),
		}

		camera.target = next_target

		break
	}
}
