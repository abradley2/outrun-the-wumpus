package system
import "core:fmt"

import "../component"
import "../entity"
import "../quadtree"
import "core:container/small_array"
import "vendor:raylib"

run_lighting_system :: proc(
	collision_quad_tree: ^quadtree.Quad_Tree,
	shadow_quad_tree: ^quadtree.Quad_Tree,
	is_shadow_layer_components: []Maybe(component.Is_Shadow_Layer),
	light_sources: []Maybe(component.Light_Source),
	position_components: []Maybe(component.Position),
	sprite_group_components: []Maybe(component.Sprite_Group),
) {
	for entity_id in 0 ..< entity.POOL_SIZE {
		if is_shadow_layer_components[entity_id] == nil {
			continue
		}

		sprite_group := (&sprite_group_components[entity_id].?) or_continue
		_ = sprite_group

		for &sprite in sprite_group.sprites {
			sprite.dimmed = 255
		}
	}

	for entity_id in 0 ..< entity.POOL_SIZE {
		if light_sources[entity_id] == nil {
			continue
		}

		light_source_position := (&position_components[entity_id].?) or_continue
		_ = light_source_position

		illuminate_squares(
			quadtree.Box {
				position = raylib.Vector2{light_source_position.x, light_source_position.y},
				w = 1,
				h = 1,
			},
			collision_quad_tree,
			shadow_quad_tree,
		)
	}
}

illuminate_squares :: proc(
	light_source: quadtree.Box,
	collision_quad_tree: ^quadtree.Quad_Tree,
	shadow_quad_tree: ^quadtree.Quad_Tree,
) {
	big_light_source_box := quadtree.Box {
		position = light_source.position - raylib.Vector2{16 * 6, light_source.h * 16 * 6},
		w        = light_source.w + (16 * 6 * 2),
		h        = light_source.h + (16 * 6 * 2),
	}
	small_light_source_box := quadtree.Box {
		position = light_source.position,
		w        = 16,
		h        = 16,
	}
	_ = small_light_source_box
	_ = big_light_source_box

	collision_tiles := make([dynamic]quadtree.Box, 0, 9, allocator = context.temp_allocator)
	shadow_tiles := make([dynamic]quadtree.Box, 0, 9, allocator = context.temp_allocator)

	stack: small_array.Small_Array(128, quadtree.Box)
	small_array.append(&stack, light_source)

	_ = collision_tiles
	_ = shadow_tiles
	_ = stack

	touched_tiles := make(map[quadtree.Box]bool, allocator = context.temp_allocator)


	for stack.len > 0 {
		node := small_array.pop_front(&stack)

		touched_tiles[node] = true

		manhatten_distance :=
			abs(node.position.x - light_source.position.x) +
			abs(node.position.y - light_source.position.y)

		manhatten_distance_squares := manhatten_distance / 14


		if manhatten_distance_squares > 14 {
			break
		}

		did_collide: bool

		shadow_nearby := quadtree.get_collisions_for(shadow_quad_tree, &shadow_tiles, node)


		for &shadow_tile in small_array.slice(&shadow_nearby) {
			shadow_tile.sprite_group_ref[shadow_tile.sprite_idx].dimmed = u8(
				255 * (manhatten_distance_squares / 14),
			)


			collisions_nearby := quadtree.get_collisions_for(
				collision_quad_tree,
				&collision_tiles,
				shadow_tile,
			)

			did_collide = collisions_nearby.len > 0
		}

		if did_collide {
			continue
		}

		// append up, down, left, right
		next_left := quadtree.Box {
			position = raylib.Vector2{node.position.x, node.position.y - 16},
			w        = 16,
			h        = 16,
		}
		if _, ok := touched_tiles[next_left]; !ok {
			small_array.append(&stack, next_left)
			touched_tiles[next_left] = true
		}

		next_right := quadtree.Box {
			position = raylib.Vector2{node.position.x, node.position.y + 16},
			w        = 16,
			h        = 16,
		}
		if _, ok := touched_tiles[next_right]; !ok {
			small_array.append(&stack, next_right)
			touched_tiles[next_right] = true
		}

		next_up := quadtree.Box {
			position = raylib.Vector2{node.position.x - 16, node.position.y},
			w        = 16,
			h        = 16,
		}
		if _, ok := touched_tiles[next_up]; !ok {
			small_array.append(&stack, next_up)
			touched_tiles[next_up] = true
		}

		next_down := quadtree.Box {
			position = raylib.Vector2{node.position.x + 16, node.position.y},
			w        = 16,
			h        = 16,
		}
		if _, ok := touched_tiles[next_down]; !ok {
			small_array.append(&stack, next_down)
			touched_tiles[next_down] = true
		}


	}


}
