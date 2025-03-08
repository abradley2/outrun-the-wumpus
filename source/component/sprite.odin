package component

import "../texture"
import "vendor:raylib"

Sprite :: struct {
	texture_id: texture.Texture_Id,
	src_rect:   raylib.Rectangle,
	dst_offset: raylib.Vector2,
	dst_width:  f32,
	dst_height: f32,
	flipped:    bool,
}
