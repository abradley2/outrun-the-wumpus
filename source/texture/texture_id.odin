package texture


// GUIDE: add a texture id to this enum when a new texture is needed, then follow the errors
Texture_Id :: enum {
	Missing,
	Tile_Map_Packed,
}

texture_id_from_path_string :: proc(path_string: string) -> Texture_Id {
	switch path_string {
	case "<MISSING>":
		return .Missing
	case "assets/kenney_tiny-dungeon/Tilemap/tilemap_packed.png":
		return .Tile_Map_Packed

	}
	return .Missing
}

texture_id_to_path_string :: proc(id: Texture_Id) -> (path_string: string) {
	switch id {
	case .Missing:
		path_string = "<MISSING>"
	case .Tile_Map_Packed:
		path_string = "assets/kenney_tiny-dungeon/Tilemap/tilemap_packed.png"
	}
	return
}
