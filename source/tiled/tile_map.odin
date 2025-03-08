package tiled

import "base:intrinsics"
import "core:container/small_array"
import "core:encoding/json"


// TODO: remove this, we are just using temp allocator
Str :: small_array.Small_Array(256, u8)

str_from_string :: proc(s: string) -> (str: Str) {
	str.len = len(s)
	intrinsics.mem_copy(&str.data, raw_data(s), str.len)
	return
}

Tile_Set_Source :: struct {
	first_gid: i64,
	source:    Str,
}

_tile_set_source_from_json :: proc(
	json_value: json.Value,
	parse_context: ^Parse_Context,
) -> (
	tile_set_source: Tile_Set_Source,
	success: bool,
) {
	push_context(parse_context, "$root")
	root_obj: json.Object
	root_obj = json_value.(json.Object) or_return
	pop_context(parse_context)

	push_context(parse_context, "firstgid")
	tile_set_source.first_gid = root_obj["firstgid"].(json.Integer) or_return
	pop_context(parse_context)

	push_context(parse_context, "source")
	tile_set_source.source = str_from_string(root_obj["source"].(json.String) or_return)
	pop_context(parse_context)

	success = true
	return
}

Layer :: struct {
	data:   [dynamic]i64,
	width:  i64,
	height: i64,
}

_layer_from_json :: proc(
	json_value: json.Value,
	parse_context: ^Parse_Context,
) -> (
	layer: Layer,
	success: bool,
) {
	push_context(parse_context, "$root")
	root_obj: json.Object
	root_obj = json_value.(json.Object) or_return
	pop_context(parse_context)

	push_context(parse_context, "height")
	layer.height = root_obj["height"].(json.Integer) or_return
	pop_context(parse_context)

	push_context(parse_context, "width")
	layer.width = root_obj["width"].(json.Integer) or_return
	pop_context(parse_context)

	push_context(parse_context, "data")
	data: json.Array
	data = root_obj["data"].(json.Array) or_return
	for elem, elem_idx in data {
		push_context_fmt(parse_context, "data[%d]", elem_idx)
		append(&layer.data, elem.(json.Integer) or_return)
		pop_context(parse_context)
	}
	pop_context(parse_context)


	success = true
	return
}

Tile_Map :: struct {
	tile_map_name:    Str,
	tile_width:       i64,
	tile_height:      i64,
	width:            i64,
	height:           i64,
	layers:           small_array.Small_Array(10, Layer),
	tile_set_sources: small_array.Small_Array(6, Tile_Set_Source),
}


Error :: enum {
	None,
	Parse_Json_Error,
	Decode_Json_Error,
}

tile_map_from_bytes_leaky :: proc(
	bytes: []u8,
	parse_context: ^Parse_Context,
	tile_map: ^Tile_Map,
	allocator := context.temp_allocator,
) -> (
	err: Error,
) {
	context.allocator = allocator

	json_value, json_parse_err := json.parse(
		bytes,
		spec = json.DEFAULT_SPECIFICATION,
		parse_integers = true,
	)

	if json_parse_err != json.Error.None {
		err = Error.Parse_Json_Error
		return
	}

	push_context(parse_context, "Tile_Map")
	decode_success: bool
	tile_map^, decode_success = _tile_map_from_json(json_value, parse_context)
	if !decode_success {
		err = Error.Decode_Json_Error
		return
	}
	pop_context(parse_context)

	return
}

_tile_map_from_json :: proc(
	json_value: json.Value,
	parse_context: ^Parse_Context,
) -> (
	tile_map: Tile_Map,
	success: bool,
) {
	push_context(parse_context, "$root")
	root_obj: json.Object
	root_obj = json_value.(json.Object) or_return
	pop_context(parse_context)

	push_context(parse_context, "height")
	tile_map.height = root_obj["height"].(json.Integer) or_return
	pop_context(parse_context)

	push_context(parse_context, "width")
	tile_map.width = root_obj["width"].(json.Integer) or_return
	pop_context(parse_context)

	push_context(parse_context, "tilewidth")
	tile_map.tile_width = root_obj["tilewidth"].(json.Integer) or_return
	pop_context(parse_context)

	push_context(parse_context, "tileheight")
	tile_map.tile_height = root_obj["tileheight"].(json.Integer) or_return
	pop_context(parse_context)

	push_context(parse_context, "tilesets")
	tile_set_sources: json.Array
	tile_set_sources = root_obj["tilesets"].(json.Array) or_return
	for tile_set_json, tile_set_source_idx in tile_set_sources {
		push_context_fmt(parse_context, "tilesets[%d]", tile_set_source_idx)
		tile_set_source: Tile_Set_Source
		tile_set_source = _tile_set_source_from_json(tile_set_json, parse_context) or_return
		small_array.append_elem(&tile_map.tile_set_sources, tile_set_source)
		pop_context(parse_context)
	}
	pop_context(parse_context)

	push_context(parse_context, "layers")
	layers: json.Array
	layers = root_obj["layers"].(json.Array) or_return
	for layer_json, layer_idx in layers {
		push_context_fmt(parse_context, "layers[%d]", layer_idx)
		layer: Layer
		layer = _layer_from_json(layer_json, parse_context) or_return
		small_array.append_elem(&tile_map.layers, layer)
		pop_context(parse_context)
	}
	pop_context(parse_context)

	success = true
	return
}
