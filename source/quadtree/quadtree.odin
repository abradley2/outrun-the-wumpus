package quadtree

import "../component"
import "core:container/small_array"
import "core:fmt"
import "core:log"
import "core:mem"
import "core:strings"
import "vendor:raylib"

tile_size :: 18

Box :: struct {
	position:         raylib.Vector2,
	w:                f32,
	h:                f32,
	is_collision:     bool,
	sprite_group_ref: ^[dynamic]component.Sprite,
	sprite_idx:       int,
}

get_collisions_for :: proc(
	tree: ^Quad_Tree,
	box_pool: ^[dynamic]Box,
	box: Box,
) -> small_array.Small_Array(64, Box) {
	resize(box_pool, 0)
	query_nearby_boxes(tree, box_pool, box)
	return collides_with_any(box, box_pool[:])
}

collides_with_any :: proc(a: Box, boxes: []Box) -> small_array.Small_Array(64, Box) {
	results: small_array.Small_Array(64, Box)
	for box in boxes {
		if collides_with(a, box) {
			if small_array.len(results) == 64 {
				break
			}
			small_array.append(&results, box)
		}
	}
	return results
}

collides_with :: proc(a: Box, b: Box) -> bool {
	return(
		a.position.x < b.position.x + b.w &&
		a.position.x + a.w > b.position.x &&
		a.position.y < b.position.y + b.h &&
		a.position.y + a.h > b.position.y \
	)
}

Quad :: struct {
	position: raylib.Vector2,
	w:        f32,
	h:        f32,
	children: ^small_array.Small_Array(4, Quad_Tree),
}

Leaf :: struct {
	nodes: small_array.Small_Array(32, Box),
}

Quad_Tree :: union {
	Quad,
	Leaf,
}


query_nearby_boxes :: proc(tree: ^Quad_Tree, results: ^[dynamic]Box, src_box: Box) {
	stack: small_array.Small_Array(64, ^Quad_Tree)
	small_array.push_front(&stack, tree)

	for stack.len > 0 {
		node := small_array.pop_front(&stack)

		switch &v in node {
		case Quad:
			collides_with_quad :=
				v.position.x < src_box.position.x + src_box.w &&
				v.position.x + v.w > src_box.position.x &&
				v.position.y < src_box.position.y + src_box.h &&
				v.position.y + v.h > src_box.position.y
			if collides_with_quad {
				for &child in small_array.slice(v.children) {
					small_array.push_front(&stack, &child)
				}
			}
		case Leaf:
			for &node in small_array.slice(&v.nodes) {
				append(results, node)
			}
		}
	}
}

log_indented_quad_tree :: proc(tree: ^Quad_Tree) {
	arena: mem.Arena
	buf: [1_024 * 64]u8
	mem.arena_init(&arena, buf[:])
	fixed_buffer_allocator := mem.arena_allocator(&arena)

	indent: small_array.Small_Array(24, byte)
	builder: strings.Builder

	context.allocator = fixed_buffer_allocator
	context.temp_allocator = fixed_buffer_allocator

	_build_quad_tree_print_string(tree, &indent, &builder)
	log.infof("Quad tree ->\n%v", strings.to_string(builder))
}

_build_quad_tree_print_string :: proc(
	tree: ^Quad_Tree,
	indent: ^small_array.Small_Array(24, byte),
	builder: ^strings.Builder,
) {
	switch &v in tree {
	case Quad:
		strings.write_string(
			builder,
			fmt.sbprintf(
				new(strings.Builder),
				"%sQuad -> position: %v, area: %v }\n",
				small_array.slice(indent),
				v.position,
				raylib.Vector2{v.w, v.h},
			),
		)
		_ = small_array.append(indent, '\t')
		for &n in small_array.slice(v.children) {
			_build_quad_tree_print_string(&n, indent, builder)
		}
		_ = small_array.pop_back(indent)
	case Leaf:
		strings.write_string(
			builder,
			fmt.sbprintf(
				new(strings.Builder),
				"%sLeaf -> positions: %v\n",
				small_array.slice(indent),
				small_array.slice(&v.nodes),
			),
		)
	}
}

insert_into_quad_tree :: proc(tree: ^Quad_Tree, node: Box) {
	switch &v in tree {
	case Quad:
		collides_with_quad :=
			v.position.x < node.position.x + node.w &&
			v.position.x + v.w > node.position.x &&
			v.position.y < node.position.y + node.h &&
			v.position.y + v.h > node.position.y

		if !collides_with_quad {
			return
		}

		for &child in small_array.slice(v.children) {
			insert_into_quad_tree(&child, node)
		}
	case Leaf:
		if v.nodes.len == 32 {
			panic("Leaf node is full")
		}
		small_array.push(&v.nodes, node)
	}
}

free_quad_tree :: proc(tree: ^Quad_Tree) {
	switch &v in tree {
	case Quad:
		for &node in small_array.slice(v.children) {
			free_quad_tree(&node)
		}
		free(v.children)
	case Leaf:
	}
}

MIN_GRID_SIZE :: 32

new_quad_tree :: proc(
	size: u32,
	allocator := context.allocator,
	position := raylib.Vector2{0, 0},
) -> Quad_Tree {
	assert(size >= MIN_GRID_SIZE, "Min grid size must be a factor of the total map size")

	size_is_even := size % 2 == 0

	if !size_is_even {
		panic("Map width and height must be even")
	}

	if size == MIN_GRID_SIZE {
		leaf := Leaf{}
		leaf.nodes = small_array.Small_Array(32, Box){}

		return leaf
	}

	quad: Quad
	quad.children = new(small_array.Small_Array(4, Quad_Tree), allocator)
	quad.position = position
	quad.w = f32(size)
	quad.h = f32(size)

	next_size := size / 2

	if next_size == MIN_GRID_SIZE {
		small_array.append(quad.children, new_quad_tree(next_size, allocator, position))
		return quad
	}

	small_array.append(quad.children, new_quad_tree(next_size, allocator, position))

	small_array.append(
		quad.children,
		new_quad_tree(
			next_size,
			allocator,
			raylib.Vector2{position.x + f32(next_size), position.y},
		),
	)

	small_array.append(
		quad.children,
		new_quad_tree(
			next_size,
			allocator,
			raylib.Vector2{position.x, position.y + f32(next_size)},
		),
	)

	small_array.append(
		quad.children,
		new_quad_tree(
			next_size,
			allocator,
			raylib.Vector2{position.x + f32(next_size), position.y + f32(next_size)},
		),
	)

	return quad
}
