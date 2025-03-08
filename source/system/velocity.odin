package system

import "../component"

run_velocity_system :: proc(
	dt: f32,
	velocity_components: []Maybe(component.Velocity),
	position_components: []Maybe(component.Position),
) {
	for &has_velocity, i in velocity_components {
		velocity := (&has_velocity.?) or_continue
		position := (&position_components[i].?) or_continue

		position.x += velocity.x * dt
		position.y += velocity.y * dt
	}
}
