package system

import "../component"
import "../entity"
import "../quadtree"
import "core:container/small_array"
import "vendor:raylib"

// TODO: this can be run async
run_lighting_system :: proc(
	light_sources: []Maybe(component.Light_Source),
	position_components: []Maybe(component.Position),
	sprite_group_components: []Maybe(component.Sprite_Group),
) {
	for &has_sprite_group in sprite_group_components {
		sprite_group := has_sprite_group.? or_continue
		for &sprite in sprite_group.sprites {
			if sprite.dimmed != nil {
				sprite.dimmed = 255
			}
		}
	}

	for entity_id in 0 ..< entity.POOL_SIZE {
		if light_sources[entity_id] == nil {
			continue
		}

		light_source_position := (&position_components[entity_id].?) or_continue
		_ = light_source_position

		for &has_sprite_group, sprite_group_entity_id in sprite_group_components {
			sprite_group := (&has_sprite_group.?) or_continue
			sprite_group_position := position_components[sprite_group_entity_id].? or_continue

			for &sprite in sprite_group.sprites {
				sprite_position :=
					sprite_group_position +
					raylib.Vector3{sprite.dst_offset.x, sprite.dst_offset.y, 0}
				_ = sprite_position

				manhatten_distance :=
					abs(sprite_position.x - light_source_position.x) +
					abs(sprite_position.y - light_source_position.y)

				manhatten_distance = manhatten_distance / 16


				sprite.dimmed = 0

				if manhatten_distance > 1 {
					sprite.dimmed = 32
				}
				if manhatten_distance > 2 {
					sprite.dimmed = 64
				}
				if manhatten_distance > 3 {
					sprite.dimmed = 128
				}
				if manhatten_distance > 4 {
					sprite.dimmed = 192
				}
				if manhatten_distance > 5 {
					sprite.dimmed = 255
				}
			}
		}
	}
}

illuminate_squares :: proc(light_source: quadtree.Box, static_collisions: ^quadtree.Quad_Tree) {
	big_light_source_box := quadtree.Box {
		position = light_source.position - raylib.Vector2{light_source.w * 8, light_source.h * 8},
		w        = light_source.w + (light_source.w * 8 * 2),
		h        = light_source.h * (light_source.h * 8 * 2),
	}
	collision_tiles := make([dynamic]quadtree.Box, 0, 9, allocator = context.temp_allocator)
	quadtree.query_nearby_boxes(static_collisions, &collision_tiles, big_light_source_box)

	stack: small_array.Small_Array(128, quadtree.Box)
	small_array.append(&stack, light_source)

	for small_array.len(stack) > 0 {
		node := small_array.pop_front(&stack)

		if quadtree.collides_with_any(node, collision_tiles[:]) {

			continue
		}
	}
}
