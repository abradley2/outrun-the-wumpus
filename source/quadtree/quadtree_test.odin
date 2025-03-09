package quadtree

import "core:log"
import "core:testing"

@(test)
_quad_tree_test :: proc(t: ^testing.T) {
	static_collisions := new_quad_tree(1024)

	insert_into_quad_tree(&static_collisions, Box{{0, 0}, 18, 18, false, nil})

	// log_indented_quad_tree(&static_collisions)

	free_quad_tree(&static_collisions)
}
