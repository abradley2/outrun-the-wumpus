package system

import "../component"
import "../controls"

run_player_controls_system :: proc(
	game_controls: controls.Controls,
	sprite_components: []Maybe(component.Sprite),
	velocity_components: []Maybe(component.Velocity),
	is_player_components: []Maybe(component.Is_Player),
	collision_box_components: []Maybe(component.Collision_Box),
) {
	for entity_id in 0 ..< len(velocity_components) {
		sprite := (&sprite_components[entity_id].?) or_continue
		velocity := (&velocity_components[entity_id].?) or_continue
		collision_box := (&collision_box_components[entity_id].?) or_continue

		if is_player_components[entity_id] == nil {
			continue
		}

		_ = sprite
		_ = collision_box
		_ = velocity
		_ = game_controls

		break
	}
}
