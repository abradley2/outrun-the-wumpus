package texture

import "../platform"
import "core:c"
import "core:log"
import "vendor:raylib"

load :: proc(texture_id: Texture_Id, texture_ptr: ^raylib.Texture) {
	log.infof("Loading texture %s", texture_id_to_path_string(texture_id))
	if texture_file_data, texture_file_data_ok := platform.read_entire_file(
		texture_id_to_path_string(texture_id),
		context.temp_allocator,
	); texture_file_data_ok {
		texture_img := raylib.LoadImageFromMemory(
			".png",
			raw_data(texture_file_data),
			c.int(len(texture_file_data)),
		)
		texture_ptr^ = raylib.LoadTextureFromImage(texture_img)
		raylib.UnloadImage(texture_img)
		log.infof("Loaded texture %s", texture_id_to_path_string(texture_id))
	} else {
		log.errorf("Failed to load texture %s", texture_id_to_path_string(texture_id))
		panic("Failed to load texture")
	}
}
