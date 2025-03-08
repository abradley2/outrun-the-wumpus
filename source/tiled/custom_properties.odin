package tiled

Player_Spawn :: struct {}

Collision_Box :: struct {}

Visible :: struct {
	visible: bool,
}

Custom_Tile_Property :: struct {
	tile_local_id:   i64,
	custom_property: Custom_Property,
}

// GUIDE: union type for special properties that appear in level map files
Custom_Property :: union {
	Visible,
	Player_Spawn,
	Collision_Box,
}

custom_property_from_raw :: proc(
	raw_custom_property: Raw_Custom_Property,
	parse_context: ^Parse_Context,
) -> (
	custom_property: Custom_Property,
	valid: bool,
) {
	push_context(parse_context, "Custom_Property")

	if raw_custom_property.name == "visible" {
		push_context(parse_context, "visible")
		switch val in raw_custom_property.value {
		case bool:
			custom_property = Visible {
				visible = val,
			}
		case string, i64, f64:
			return
		}
		pop_context(parse_context)
	}

	if raw_custom_property.name == "collision_tile" {
		push_context(parse_context, "collision_tile")
		switch val in raw_custom_property.value {
		case bool:
			if val {
				custom_property = Collision_Box{}
			}
		case i64, f64, string:
			return
		}
		pop_context(parse_context)
	}

	if raw_custom_property.name == "spawn_for" {
		push_context(parse_context, "spawn_for")
		switch val in raw_custom_property.value {
		case string:
			switch val {
			case "player":
				custom_property = Player_Spawn{}
			case:
				return
			}
		case i64, f64, bool:
			return
		}
		pop_context(parse_context)
	}

	pop_context(parse_context)
	valid = true
	return
}
