package texture

import "core:reflect"
import "core:testing"

@(test)
_texture_id_bidirect_test :: proc(t: ^testing.T) {
	enum_names := reflect.enum_field_names(Texture_Id)

	for name in enum_names {
		e, _ := reflect.enum_from_name(Texture_Id, name)
		path_string := texture_id_to_path_string(e)
		e2 := texture_id_from_path_string(path_string)
		testing.expect(t, e == e2)
	}
}
