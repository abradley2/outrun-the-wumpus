package entity

import "../component"
import "vendor:raylib"

POOL_SIZE :: 4_096

// GUIDE: when a component needs an allocated resources, add it here. See sprite vectors example
Pool :: struct {
	current_gid:      u64,
	available:        [POOL_SIZE]bool,
	lid_to_gid:       [POOL_SIZE]u64,
	renderables:      [POOL_SIZE]int,
	sprite_vectors:   [POOL_SIZE][dynamic]component.Sprite,
	animation_frames: [POOL_SIZE][dynamic]component.Animation_Frame,
}

bubble_sort_renderables :: proc(
	pool: ^Pool,
	positions: []Maybe(component.Position),
	max_idx: int,
) -> (
	next_max_idx: int,
) {
	work_done: int
	for i in 0 ..< max_idx {
		for j in 1 ..< max_idx - i - 1 {
			l_val := positions[pool.renderables[j - 1]].? or_else raylib.Vector3{0, 0, 0}
			r_val := positions[pool.renderables[j]].? or_else raylib.Vector3{0, 0, 0}
			if l_val.z > r_val.z {
				pool.renderables[j - 1], pool.renderables[j] =
					pool.renderables[j], pool.renderables[j - 1]
			}
			work_done = work_done + 1
			if work_done >= 4096 * 24 {
				next_max_idx = max_idx - i
				return
			}
		}
	}

	return
}

free_pool :: proc(pool: ^Pool) {
	for sprite_vector in pool.sprite_vectors {
		delete_dynamic_array(sprite_vector)
	}
	for animation_frame in pool.animation_frames {
		delete_dynamic_array(animation_frame)
	}
	free(pool)
}

new_pool :: proc(allocator := context.allocator) -> ^Pool {
	pool := new(Pool, allocator)

	for i in 0 ..< POOL_SIZE {
		pool.sprite_vectors[i] = make([dynamic]component.Sprite, allocator)
		pool.animation_frames[i] = make([dynamic]component.Animation_Frame, allocator)
		pool.available[i] = true
	}

	return pool
}

alloc_animation_frames :: proc(pool: ^Pool, local_id: int) -> ^[dynamic]component.Animation_Frame {
	return &pool.animation_frames[local_id]
}

free_animation_frames :: proc(pool: ^Pool, local_id: int) {
	resize(&pool.animation_frames[local_id], 0)
}

alloc_sprite_vector :: proc(pool: ^Pool, local_id: int) -> ^[dynamic]component.Sprite {
	return &pool.sprite_vectors[local_id]
}

free_sprite_vector :: proc(pool: ^Pool, local_id: int) {
	resize(&pool.sprite_vectors[local_id], 0)
}

free_entity :: proc(pool: ^Pool, local_id: int) {
	pool.available[local_id] = true

	free_sprite_vector(pool, local_id)
	free_animation_frames(pool, local_id)

	for i in 0 ..< len(pool.renderables) {
		if pool.renderables[i] == local_id {
			pool.renderables[i] = 0
			break
		}
	}
}

alloc_entity :: proc(pool: ^Pool, is_renderable: bool) -> (entity_ref: EntityRef) {
	pool.current_gid = pool.current_gid + 1

	entity_ref.global_id = pool.current_gid

	for i in 1 ..< POOL_SIZE {
		if pool.available[i] {
			entity_ref.local_id = i
			pool.available[i] = false
			break
		}
	}

	for i in 0 ..< len(pool.renderables) {
		renderable_lid := pool.renderables[i]
		if renderable_lid == 0 {
			pool.renderables[i] = entity_ref.local_id
			break
		}
	}

	return
}
