package system

import "../component"
import "../controls"
import "../entity"
import "../quadtree"
import "vendor:raylib"

run_player_controls_system :: proc(
	game_controls: controls.Controls,
	static_collisions: ^quadtree.Quad_Tree,
	position_components: []Maybe(component.Position),
	is_player_components: []Maybe(component.Is_Player),
	collision_box_components: []Maybe(component.Collision_Box),
) {
	nearby_collision_boxes := make([dynamic]quadtree.Box, 0, 9, allocator = context.temp_allocator)

	for entity_id in 0 ..< entity.POOL_SIZE {
		position := (&position_components[entity_id].?) or_continue
		collision_box := (&collision_box_components[entity_id].?) or_continue

		if is_player_components[entity_id] == nil {
			continue
		}

		player_origin := position^

		dest_origin: Maybe(raylib.Vector3)

		if game_controls.left_just_pressed {
			dest_origin = player_origin - raylib.Vector3{collision_box.size.x, 0, 0}
		}

		if game_controls.right_just_pressed {
			dest_origin = player_origin + raylib.Vector3{collision_box.size.x, 0, 0}
		}

		if game_controls.up_just_pressed {
			dest_origin = player_origin - raylib.Vector3{0, collision_box.size.y, 0}
		}

		if game_controls.down_just_pressed {
			dest_origin = player_origin + raylib.Vector3{0, collision_box.size.y, 0}
		}

		if dest, ok := dest_origin.?; ok {
			resize(&nearby_collision_boxes, 0)

			dest_box := quadtree.Box {
				position = raylib.Vector2 {
					dest.x + (collision_box.size.x / 2),
					dest.y + (collision_box.size.y / 2),
				},
				w        = 1,
				h        = 1,
			}
			quadtree.query_nearby_boxes(static_collisions, &nearby_collision_boxes, dest_box)

			did_collide: bool
			check_collisions: for nearby_collision_box in nearby_collision_boxes {
				if quadtree.collides_with(dest_box, nearby_collision_box) {
					did_collide = true
					break check_collisions
				}
			}

			if !did_collide {
				position.x = dest.x
				position.y = dest.y
			}
		}

		break
	}
}
