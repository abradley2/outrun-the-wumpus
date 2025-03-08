
package tiled

import "base:intrinsics"
import "core:container/small_array"
import "core:fmt"
import "core:mem/virtual"
import "core:strings"

Parse_Context :: struct {
	stack: small_array.Small_Array(12, Str),
}

push_context :: proc(parse_context: ^Parse_Context, msg: string) {
	str_msg: Str
	str_msg.len = len(msg)
	intrinsics.mem_copy(&str_msg.data, raw_data(msg), str_msg.len)
	small_array.append_elem(&parse_context.stack, str_msg)
}

push_context_fmt :: proc(parse_context: ^Parse_Context, fmt_str: string, fmt_args: ..any) {
	arena: virtual.Arena
	buff: [512]u8
	_ = virtual.arena_init_buffer(&arena, buff[:])
	allocator := virtual.arena_allocator(&arena)

	builder := strings.builder_make(allocator)
	msg := fmt.sbprintf(&builder, fmt_str, fmt_args)
	push_context(parse_context, msg)
}

pop_context :: proc(parse_context: ^Parse_Context) {
	small_array.pop_back(&parse_context.stack)
}

print_context :: proc(
	parse_context: ^Parse_Context,
	allocator := context.allocator,
) -> (
	output: strings.Builder,
) {
	output = strings.builder_make(allocator)

	i: int = parse_context.stack.len - 1
	stack := parse_context.stack.data
	for {
		msg := stack[i]
		strings.write_bytes(&output, msg.data[0:msg.len])
		if i == 0 {
			break
		}
		i = i - 1
		strings.write_string(&output, " <- ")
	}

	return
}



