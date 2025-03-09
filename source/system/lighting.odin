package system

import "../component"
import "../entity"
import "../quadtree"
import "core:fmt"
import "vendor:raylib"

run_lighting_system :: proc(
	sprite_quad_tree: ^quadtree.Quad_Tree,
	light_sources: []Maybe(component.Light_Source),
	position_components: []Maybe(component.Position),
	sprite_group_components: []Maybe(component.Sprite_Group),
) {
	for &has_sprite_group in sprite_group_components {
		sprite_group := has_sprite_group.? or_continue
		for &sprite in sprite_group.sprites {
			if sprite.dimmed != nil {
				sprite.dimmed = 180
			}
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
			sprite_quad_tree,
		)
	}
}

illuminate_squares :: proc(light_source: quadtree.Box, sprite_quad_tree: ^quadtree.Quad_Tree) {
	big_light_source_box := quadtree.Box {
		position = light_source.position - raylib.Vector2{light_source.w * 16, light_source.h * 16},
		w        = light_source.w + (light_source.w * 16 * 2),
		h        = light_source.h + (light_source.h * 16 * 2),
	}
	collision_tiles := make([dynamic]quadtree.Box, 0, 9, allocator = context.temp_allocator)
	quadtree.query_nearby_boxes(sprite_quad_tree, &collision_tiles, big_light_source_box)

	for &tile in collision_tiles {
		fmt.printf("Current dim level = %d\n", tile.sprite_group_ref[tile.sprite_idx].dimmed)
		tile.sprite_group_ref[tile.sprite_idx].dimmed = 0
	}


}
