package game

import "./entity"
import "./quadtree"
import "./tiled"
import "core:reflect"
import "core:testing"

@(test)
_load_map_test :: proc(t: ^testing.T) {
	tile_map_ids := reflect.enum_field_names(tiled.Map_Id)

	entity_pool := entity.new_pool(context.allocator)

	for id in tile_map_ids {
		w := new(World)
		defer free(w, context.allocator)

		tile_map_id, _ := reflect.enum_from_name(tiled.Map_Id, id)
		static_collisions, sprite_quad_tree, ok := load_world(tile_map_id, w, entity_pool)
		testing.expect(t, ok)
		free_all(context.temp_allocator)
		quadtree.free_quad_tree(static_collisions)
		free(static_collisions)
		quadtree.free_quad_tree(sprite_quad_tree)
		free(sprite_quad_tree)
	}

	entity.free_pool(entity_pool)
}
