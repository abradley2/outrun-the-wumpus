package entity

import "core:testing"

@(test)
_pool_test :: proc(t: ^testing.T) {
	entity_pool := new_pool()
	defer free_pool(entity_pool)

	ref_a := alloc_entity(entity_pool, false)
	ref_b := alloc_entity(entity_pool, false)

	testing.expect(t, ref_a.local_id != ref_b.local_id)
}
