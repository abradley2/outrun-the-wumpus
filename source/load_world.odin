package game

import "./component"
import "./entity"
import "./platform"
import "./quadtree"
import "./texture"
import "./tiled"
import "core:container/small_array"
import "core:fmt"
import "core:log"
import "core:path/slashpath"
import "core:strings"
import "vendor:raylib"

load_dark_layer :: proc(
	world: ^World,
	entity_pool: ^entity.Pool,
) -> (
	dark_tile_quad_tree: ^quadtree.Quad_Tree,
) {
	fmt.printf("Loading dark layer\n")
	dark_tile_quad_tree = new(quadtree.Quad_Tree)
	dark_tile_quad_tree^ = quadtree.new_quad_tree(1024)

	dark_tile_sprite_group_ref := entity.alloc_entity(entity_pool, true)
	sprite_group := entity.alloc_sprite_vector(entity_pool, dark_tile_sprite_group_ref.local_id)

	world.position[dark_tile_sprite_group_ref.local_id] = component.Position{0, 0, 99}

	world.is_shadow_layer[dark_tile_sprite_group_ref.local_id] = component.Is_Shadow_Layer{}

	world.sprite_group[dark_tile_sprite_group_ref.local_id] = component.Sprite_Group {
		sprites = sprite_group,
	}

	x: f32
	y: f32


	for x < 1024 {
		y = 0
		for y < 1024 {
			sprite := component.Sprite {
				texture_id = texture.Texture_Id.Missing,
				src_rect   = raylib.Rectangle{},
				dst_offset = raylib.Vector2{x, y},
				dst_width  = 16,
				dst_height = 16,
				dimmed     = 255,
			}

			append(sprite_group, sprite)

			quadtree.insert_into_quad_tree(
				dark_tile_quad_tree,
				quadtree.Box {
					position = raylib.Vector2{x, y},
					w = 16,
					h = 16,
					is_collision = false,
					sprite_group_ref = sprite_group,
					sprite_idx = len(sprite_group) - 1,
				},
			)

			y += 16
		}
		x += 16
	}

	return
}

load_world :: proc(
	map_id: tiled.Map_Id,
	world: ^World,
	entity_pool: ^entity.Pool,
) -> (
	static_collisions: ^quadtree.Quad_Tree,
	dark_tile_quad_tree: ^quadtree.Quad_Tree,
	ok: bool,
) {
	static_collisions = new(quadtree.Quad_Tree)
	static_collisions^ = quadtree.new_quad_tree(1024)


	fmt.printf("Loaded dark layer\n")

	sprite_quad_tree := new(quadtree.Quad_Tree)
	sprite_quad_tree^ = quadtree.new_quad_tree(1024)
	_ = sprite_quad_tree


	context.allocator = context.temp_allocator
	ok = _load_world(map_id, world, entity_pool, static_collisions, dark_tile_quad_tree)

	dark_tile_quad_tree = load_dark_layer(world, entity_pool)
	return
}

_load_world :: proc(
	map_id: tiled.Map_Id,
	world: ^World,
	entity_pool: ^entity.Pool,
	static_collisions: ^quadtree.Quad_Tree,
	dark_tile_quad_tree: ^quadtree.Quad_Tree,
) -> (
	ok: bool,
) {
	tile_map := new(tiled.Tile_Map)

	path_to_map_file := tiled.map_id_to_file_path_string(map_id)
	map_file_dir := slashpath.dir(path_to_map_file)

	// LOAD TILE MAPS
	if level_map_bytes, read_success := platform.read_entire_file(path_to_map_file); read_success {
		parse_context: tiled.Parse_Context

		tile_map_err: tiled.Error
		tile_map_err = tiled.tile_map_from_bytes_leaky(level_map_bytes, &parse_context, tile_map)

		if tile_map_err != tiled.Error.None {
			err_ctx := tiled.print_context(&parse_context)
			log.errorf("Error loading map: %v", tile_map_err)
			log.errorf(strings.to_string(err_ctx))
			ok = false
			return
		} else {
			log.infof("Loaded map: %s", path_to_map_file)
		}
	} else {
		ok = false
		return
	}

	// LOAD TILE SETS
	tile_sets := make(
		[dynamic]tiled.Tile_Set,
		tile_map.tile_set_sources.len,
		tile_map.tile_set_sources.len,
	)

	for &tile_set_source, tile_set_idx in small_array.slice(&tile_map.tile_set_sources) {
		tile_set_source_file := slashpath.join(
			[]string{map_file_dir, string(small_array.slice(&tile_set_source.source))},
		)

		tile_set_dir := slashpath.dir(tile_set_source_file)

		if tile_set_source_data, tile_set_source_ok := platform.read_entire_file(
			tile_set_source_file,
		); tile_set_source_ok {
			parse_context: tiled.Parse_Context
			tile_set_err := tiled.tile_set_from_bytes_leaky(
				tile_set_source.first_gid,
				tile_set_source_data,
				&parse_context,
				&tile_sets[tile_set_idx],
			)

			tile_set_image := slashpath.join([]string{tile_set_dir, tile_sets[tile_set_idx].image})
			tile_sets[tile_set_idx].texture_id = texture.texture_id_from_path_string(
				tile_set_image,
			)

			if tile_set_err != tiled.Error.None {
				err_ctx := tiled.print_context(&parse_context)
				log.errorf("Error loading Tileset: %v", tile_set_err)
				log.errorf(strings.to_string(err_ctx))
				ok = false
				return
			}
			log.infof("Loaded Tileset: %s", tile_set_source_file)
		} else {
			log.errorf("Error loading Tileset: %s", tile_set_source_file)
			ok = false
			return
		}
	}

	// POPULATE WORLD
	_populate_world(world, entity_pool, static_collisions, tile_map, tile_sets)

	ok = true
	return
}

_populate_world :: proc(
	world: ^World,
	entity_pool: ^entity.Pool,
	static_collisions: ^quadtree.Quad_Tree,
	tile_map: ^tiled.Tile_Map,
	tile_sets: [dynamic]tiled.Tile_Set,
) {
	for tile_layer, layer_idx in small_array.slice(&tile_map.layers) {
		layer_entity_ref := entity.alloc_entity(entity_pool, true)

		layer_entity_sprite_vector := entity.alloc_sprite_vector(
			entity_pool,
			layer_entity_ref.local_id,
		)

		sprite_group := component.Sprite_Group {
			sprites = layer_entity_sprite_vector,
		}

		world.sprite_group[layer_entity_ref.local_id] = sprite_group

		layer_position := component.Position{0, 0, f32(layer_idx)}

		world.position[layer_entity_ref.local_id] = layer_position

		for global_id, tile_idx in tile_layer.data {
			if global_id == 0 {
				continue
			}

			dst_y_pos := (i64(tile_idx) / tile_map.width) * tile_map.tile_width
			dst_x_pos := (i64(tile_idx) % tile_map.width) * tile_map.tile_height

			tile_set: tiled.Tile_Set
			for ts in tile_sets {
				if global_id >= ts.first_gid && global_id < ts.first_gid + ts.tile_count {
					tile_set = ts
					break
				}
			}

			local_id := global_id - tile_set.first_gid

			properties: small_array.Small_Array(20, tiled.Custom_Property)
			get_properties: {
				tile_set_properties := tile_set.properties.? or_break get_properties
				for custom_tile_property in tile_set_properties {
					if custom_tile_property.tile_local_id == local_id {
						small_array.append(&properties, custom_tile_property.custom_property)
					}
				}
			}

			src_y_pos := (i64(local_id) / tile_set.columns) * tile_set.tile_width
			src_x_pos := (i64(local_id) % tile_set.columns) * tile_set.tile_height

			sprite_rect := raylib.Rectangle {
				x      = f32(src_x_pos),
				y      = f32(src_y_pos),
				width  = f32(tile_set.tile_width),
				height = f32(tile_set.tile_height),
			}

			dst_offset := raylib.Vector2{f32(dst_x_pos), f32(dst_y_pos)}
			sprite := component.Sprite {
				texture_id = tile_set.texture_id,
				src_rect   = sprite_rect,
				dst_offset = dst_offset,
				dst_width  = f32(tile_set.tile_width),
				dst_height = f32(tile_set.tile_height),
				dimmed     = 0,
			}

			did_spawn := entity.check_spawn(
				world,
				small_array.slice(&properties),
				entity_pool,
				layer_position + raylib.Vector3{dst_offset[0], dst_offset[1], 0},
			)

			if did_spawn {
				continue
			}

			append(sprite_group.sprites, sprite)

			is_collision := false
			for custom_property in small_array.slice(&properties) {
				#partial switch property in custom_property {
				case tiled.Collision_Box:
					static_collision_box := quadtree.Box {
						position         = raylib.Vector2 {
							layer_position[0],
							layer_position[1],
						} + raylib.Vector2{dst_offset[0], dst_offset[1]},
						w                = sprite.dst_width,
						h                = sprite.dst_height,
						is_collision     = true,
						sprite_group_ref = sprite_group.sprites,
						sprite_idx       = len(sprite_group.sprites) - 1,
					}
					is_collision = true
					quadtree.insert_into_quad_tree(static_collisions, static_collision_box)
				}
			}
		}
	}
}
