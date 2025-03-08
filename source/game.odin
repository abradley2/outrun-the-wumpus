package game


import "./component"
import "./controls"
import "./entity"
import "./quadtree"
import "./system"
import "./texture"
import "./tiled"
import "core:c"
import "core:fmt"
import "vendor:raylib"

run: bool

World :: #soa[entity.POOL_SIZE]entity.Entity

_world: World
entity_pool: ^entity.Pool

tile_map_packed_texture: raylib.Texture
tile_map_backgrounds_packed_texture: raylib.Texture
characters_packed_texture: raylib.Texture

ui_button_blue_texture: raylib.Texture
ui_arrow_basic_blue_texture: raylib.Texture

game_width :: f32(480.0)

screen_width: f32
screen_height: f32

paralax_camera_target: raylib.Vector2
camera_target: raylib.Vector2

init :: proc() {
	run = true
	raylib.SetConfigFlags({.WINDOW_RESIZABLE, .VSYNC_HINT})
	raylib.InitWindow(1280, 720, "Outrun the Wumpus")

	entity_pool = entity.new_pool(context.allocator)

	raylib.SetTargetFPS(61)

	screen_width = f32(raylib.GetScreenWidth())
	screen_height = f32(raylib.GetScreenHeight())

	// Load textures
	texture.load(texture.Texture_Id.Tile_Map_Packed, &tile_map_packed_texture)
}


// GUIDE: editing this variable will cause the map to change
Scene_Error :: struct {}

Scene_Loaded :: struct {
	map_id:            tiled.Map_Id,
	static_collisions: ^quadtree.Quad_Tree,
}

Scene_State :: union {
	Scene_Error,
	Scene_Loaded,
}

run_scene_state :: proc(
	state: ^Scene_State,
	w: ^World,
	entity_pool: ^entity.Pool,
	target_map_id: Maybe(tiled.Map_Id),
) {
	map_id, has_map_id := target_map_id.?

	if !has_map_id {
		if s, scene_loaded := state.(Scene_Loaded); scene_loaded {
			quadtree.free_quad_tree(s.static_collisions)
			free(s.static_collisions)
		}
		return
	}

	switch v in state {
	case nil:
		if world_static_collisions, ok := load_world(map_id, w, entity_pool); ok {
			state^ = Scene_Loaded {
				map_id            = map_id,
				static_collisions = world_static_collisions,
			}
		} else {
			state^ = Scene_Error{}
		}
		free_all(context.temp_allocator)
	case Scene_Loaded:
		if v.map_id != map_id {
			quadtree.free_quad_tree(v.static_collisions)
			free(v.static_collisions)

			if world_static_collisions, ok := load_world(v.map_id, w, entity_pool); ok {
				state^ = Scene_Loaded {
					map_id            = v.map_id,
					static_collisions = world_static_collisions,
				}
			} else {
				state^ = Scene_Error{}
			}
			free_all(context.temp_allocator)
		}
	case Scene_Error:
	}
}

set_current_map_id: tiled.Map_Id = tiled.Map_Id.Level01
scene_state: Scene_State = nil

z_sort_idx: int
update :: proc() {
	world := &_world

	if z_sort_idx == 0 {
		z_sort_idx = entity.POOL_SIZE
	}
	z_sort_idx = entity.bubble_sort_renderables(entity_pool, world.position[:], z_sort_idx)

	run_scene_state(&scene_state, world, entity_pool, set_current_map_id)

	camera := raylib.Camera2D {
		offset   = raylib.Vector2{0, 0},
		target   = camera_target,
		rotation = 0,
		zoom     = 1,
	}

	if raylib.IsWindowResized() {
		screen_width = f32(raylib.GetScreenWidth())
		screen_height = f32(raylib.GetScreenHeight())
		raylib.SetWindowSize(raylib.GetScreenWidth(), raylib.GetScreenHeight())
	}

	zoom := screen_width / game_width
	camera.zoom = zoom

	loaded_scene, scene_is_loaded := scene_state.(Scene_Loaded)
	if !scene_is_loaded {
		return
	}

	static_collisions := loaded_scene.static_collisions
	_ = static_collisions

	controls := controls.run_keyboard_inputs()
	delta := raylib.GetFrameTime() / 0.01666
	fmt.printf("delta: %f\n", delta)
	if delta > 2 {
		delta = 2
	}


	system.run_velocity_system(delta, world.velocity[:], world.position[:])
	system.run_player_controls_system(
		controls,
		world.sprite[:],
		world.velocity[:],
		world.is_player[:],
		world.collision_box[:],
	)
	system.run_animation_system(delta, world.sprite[:], world.animation_frames[:])
	system.run_camera_follow_system(&camera, world.is_player[:], world.position[:])

	raylib.BeginDrawing()
	raylib.ClearBackground({194, 227, 232, 255})

	raylib.BeginMode2D(camera)

	{
		for entity_id in entity_pool.renderables {
			position := world.position[entity_id].? or_continue
			sprite, has_sprite := world.sprite[entity_id].?
			sprite_group, has_sprite_group := world.sprite_group[entity_id].?

			if has_sprite_group {
				for sprite_group_sprite in sprite_group.sprites {
					render_sprite(position, sprite_group_sprite)
				}
			}

			if has_sprite {
				render_sprite(position, sprite)
			}
		}
	}


	raylib.EndMode2D()

	raylib.EndDrawing()

	free_all(context.temp_allocator)
}

render_sprite :: proc(position: raylib.Vector3, sprite: component.Sprite) -> (did_render: bool) {
	sprite_position := raylib.Vector2{position[0], position[1]} + sprite.dst_offset

	found_texture: Maybe(raylib.Texture)
	switch sprite.texture_id {
	case texture.Texture_Id.Tile_Map_Packed:
		found_texture = tile_map_packed_texture
	case texture.Texture_Id.Missing:
		found_texture = nil
	}
	texture := found_texture.? or_return

	dst_rect := raylib.Rectangle {
		x      = sprite_position[0],
		y      = sprite_position[1],
		width  = sprite.dst_width,
		height = sprite.dst_height,
	}

	src_rect := raylib.Rectangle {
		x      = sprite.src_rect.x,
		y      = sprite.src_rect.y,
		width  = sprite.src_rect.width,
		height = sprite.src_rect.height,
	}

	if src_rect.width < 1 {
		src_rect.width = f32(texture.width)
	}

	if src_rect.height < 1 {
		src_rect.height = f32(texture.height)
	}

	if sprite.flipped {
		src_rect.width *= -1
	}

	raylib.DrawTexturePro(texture, src_rect, dst_rect, {0, 0}, 0, raylib.WHITE)
	did_render = true
	return
}

parent_window_size_changed :: proc(w, h: int) {
	raylib.SetWindowSize(c.int(w), c.int(h))
}

shutdown :: proc() {
	switch v in scene_state {
	case Scene_Loaded:
		quadtree.free_quad_tree(v.static_collisions)
		free(v.static_collisions)
	case nil, Scene_Error:
	}
	raylib.CloseWindow()
}

should_run :: proc() -> bool {
	when ODIN_OS != .JS {
		if raylib.WindowShouldClose() {
			run = false
		}
	}

	return run
}
