package system

import "../component"
import "../entity"
import "core:container/small_array"
import "vendor:raylib"

run_movement_command_system :: proc(
	movement_command_components: []Maybe(component.Movement_Command),
	position_components: []Maybe(component.Position),
) {
	remove_movement_command_components: small_array.Small_Array(entity.POOL_SIZE, int)

	for entity_id in 0 ..< len(movement_command_components) {
		movement_command := (&movement_command_components[entity_id].?) or_continue
		position := (&position_components[entity_id].?) or_continue

		direction := raylib.Vector3 {
			movement_command.target.x - position.x,
			movement_command.target.y - position.y,
			movement_command.target.z - position.z,
		}

		distance := raylib.Vector3Length(direction)

		if distance < movement_command.speed {
			position.x = movement_command.target.x
			position.y = movement_command.target.y
			position.z = movement_command.target.z
			small_array.append(&remove_movement_command_components, entity_id)
		} else {
			direction = raylib.Vector3Normalize(direction)
			direction = direction * movement_command.speed

			position.x += direction.x
			position.y += direction.y
			position.z += direction.z
		}
	}

	for entity_id in small_array.slice(&remove_movement_command_components) {
		movement_command_components[entity_id] = nil
	}
}
