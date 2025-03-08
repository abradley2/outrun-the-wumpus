package system

import "../component"

run_animation_system :: proc(
	dt: f32,
	sprite_components: []Maybe(component.Sprite),
	animation_frames_components: []Maybe(component.Animation_Frames),
) {
	for entity_id in 0 ..< len(sprite_components) {
		sprite := (&sprite_components[entity_id].?) or_continue
		animation_frames := (&animation_frames_components[entity_id].?) or_continue

		animation_frames.current_duration += dt
		if animation_frames.current_duration >= animation_frames.frame_duration {
			frame_count := len(animation_frames.frames)
			next_frame_idx := animation_frames.current_frame_idx + 1
			if next_frame_idx >= frame_count {
				next_frame_idx = 0
			}

			next_frame := animation_frames.frames[next_frame_idx]
			sprite.texture_id = next_frame.texture_id
			sprite.src_rect = next_frame.src_rect
			animation_frames.current_frame_idx = next_frame_idx
			animation_frames.current_duration = 0
		}
	}
}
