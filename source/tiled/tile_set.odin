package tiled

import "../texture"
import "core:encoding/json"

Tile_Set :: struct {
	columns:     i64,
	image:       string,
	first_gid:   i64,
	texture_id:  texture.Texture_Id,
	spacing:     i64,
	tile_count:  i64,
	tile_height: i64,
	tile_width:  i64,
	properties:  Maybe([dynamic]Custom_Tile_Property),
}

tile_set_from_bytes_leaky :: proc(
	first_gid: i64,
	bytes: []u8,
	parse_context: ^Parse_Context,
	tile_set: ^Tile_Set,
	allocator := context.temp_allocator,
) -> (
	err: Error,
) {
	context.allocator = allocator

	json_value, parse_err := json.parse(bytes, json.DEFAULT_SPECIFICATION, true, allocator)
	if parse_err != json.Error.None {
		err = Error.Parse_Json_Error
		return
	}

	push_context(parse_context, "Tile_Set")
	success: bool
	tile_set^, success = _tile_set_from_json(first_gid, json_value, parse_context)

	if !success {
		err = Error.Decode_Json_Error
		return
	}
	pop_context(parse_context)

	return
}

_tile_set_from_json :: proc(
	first_gid: i64,
	json_value: json.Value,
	parse_context: ^Parse_Context,
) -> (
	tile_set: Tile_Set,
	success: bool,
) {
	tile_set.first_gid = first_gid

	push_context(parse_context, "$root")
	root_obj: json.Object
	root_obj = json_value.(json.Object) or_return
	pop_context(parse_context)

	push_context(parse_context, "columns")
	tile_set.columns = root_obj["columns"].(json.Integer) or_return
	pop_context(parse_context)

	push_context(parse_context, "image")
	tile_set.image = root_obj["image"].(json.String) or_return
	pop_context(parse_context)

	push_context(parse_context, "spacing")
	tile_set.spacing = root_obj["spacing"].(json.Integer) or_return
	pop_context(parse_context)

	push_context(parse_context, "tilecount")
	tile_set.tile_count = root_obj["tilecount"].(json.Integer) or_return
	pop_context(parse_context)

	push_context(parse_context, "tileheight")
	tile_set.tile_height = root_obj["tileheight"].(json.Integer) or_return
	pop_context(parse_context)

	push_context(parse_context, "tilewidth")
	tile_set.tile_width = root_obj["tilewidth"].(json.Integer) or_return
	pop_context(parse_context)

	parse_properties: {
		push_context(parse_context, "tiles")
		tiles_attr_value, has_tiles_attr := root_obj["tiles"]
		if has_tiles_attr {
			tile_set.properties = custom_property_list_from_json(
				tiles_attr_value,
				parse_context,
			) or_return
		}
		pop_context(parse_context)
	}

	success = true
	return
}


Custom_Property_Value :: union {
	i64,
	f64,
	bool,
	string,
}

custom_property_list_from_json :: proc(
	json_value: json.Value,
	parse_context: ^Parse_Context,
) -> (
	custom_properties_list: [dynamic]Custom_Tile_Property,
	success: bool,
) {
	push_context(parse_context, "$root")
	raw_properties_list := json_value.(json.Array) or_return
	pop_context(parse_context)

	for raw_property, idx in raw_properties_list {
		push_context_fmt(parse_context, "raw_properties[%d]root", idx)
		property_obj := raw_property.(json.Object) or_return
		pop_context(parse_context)

		push_context_fmt(parse_context, "raw_properties[%d]id", idx)
		tile_local_id := property_obj["id"].(json.Integer) or_return
		pop_context(parse_context)

		tile_object_group_arr_value, has_object_group_arr := property_obj["objectgroup"]
		if has_object_group_arr {
			push_context_fmt(parse_context, "raw_properties[%d]objectgroup", idx)
			tile_object_group_arr := tile_object_group_arr_value.(json.Object) or_return
			pop_context(parse_context)

			_ = tile_object_group_arr
		}

		tile_properties_arr_value, has_tile_properties_arr := property_obj["properties"]
		if has_tile_properties_arr {
			push_context_fmt(parse_context, "raw_properties[%d]properties", idx)
			tile_properties_arr := tile_properties_arr_value.(json.Array) or_return
			pop_context(parse_context)

			for raw_tile_property_json, tile_property_idx in tile_properties_arr {
				push_context_fmt(
					parse_context,
					"raw_properties[%d]properties[%d]",
					idx,
					tile_property_idx,
				)

				push_context(parse_context, "raw")
				raw_property := raw_custom_property_from_json(
					raw_tile_property_json,
					parse_context,
				) or_return
				pop_context(parse_context)

				push_context(parse_context, "decoded")
				custom_property := custom_property_from_raw(raw_property, parse_context) or_return
				append(
					&custom_properties_list,
					Custom_Tile_Property {
						tile_local_id = tile_local_id,
						custom_property = custom_property,
					},
				)
				pop_context(parse_context)
			}
		}
	}


	success = true
	return
}

Raw_Custom_Property :: struct {
	tile_local_id: i64,
	name:          string,
	value:         Custom_Property_Value ``,
}

raw_custom_property_from_json :: proc(
	json_value: json.Value,
	parse_context: ^Parse_Context,
) -> (
	raw_custom_property: Raw_Custom_Property,
	success: bool,
) {
	push_context(parse_context, "Raw_Custom_Property")
	root_obj := json_value.(json.Object) or_return
	pop_context(parse_context)

	push_context(parse_context, "name")
	raw_custom_property.name = root_obj["name"].(json.String) or_return
	pop_context(parse_context)

	push_context(parse_context, "value")
	switch val in root_obj["value"] {
	case json.String:
		raw_custom_property.value = root_obj["value"].(json.String)
	case json.Boolean:
		raw_custom_property.value = root_obj["value"].(json.Boolean)
	case json.Integer:
		raw_custom_property.value = root_obj["value"].(json.Integer)
	case json.Float:
		raw_custom_property.value = root_obj["value"].(json.Float)
	case json.Array, json.Null, json.Object:
		return
	}
	pop_context(parse_context)

	success = true
	return
}
