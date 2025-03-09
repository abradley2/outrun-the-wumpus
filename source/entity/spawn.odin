package entity

import "../component"
import "../texture"
import "../tiled"
import "vendor:raylib"

// GUIDE: spawn entities in response to special tiles on the map
check_spawn :: proc(
	world: ^#soa[POOL_SIZE]Entity,
	custom_properties: []tiled.Custom_Property,
	entity_pool: ^Pool,
	position: raylib.Vector3,
) -> (
	did_spawn: bool,
) {
	for custom_property in custom_properties {
		#partial switch property in custom_property {
		case tiled.Player_Spawn:
			did_spawn = true

			player_entity_ref := alloc_entity(entity_pool, true)

			world.is_player[player_entity_ref.local_id] = component.Is_Player{}

			world.position[player_entity_ref.local_id] = position + raylib.Vector3{0, -16, 0}

			world.light_source[player_entity_ref.local_id] = component.Light_Source{}

			world.velocity[player_entity_ref.local_id] = raylib.Vector2{0, 0}
			world.collision_box[player_entity_ref.local_id] = component.Collision_Box {
				offset = raylib.Vector2{0, 0},
				size   = raylib.Vector2{16, 16},
			}
			world.sprite[player_entity_ref.local_id] = component.Sprite {
				texture_id = texture.Texture_Id.Tile_Map_Packed,
				src_rect   = raylib.Rectangle{16, 128, 16, 16},
				dst_offset = {0, 0},
				dst_width  = 16,
				dst_height = 16,
			}
		}
	}

	return
}
