shader_type canvas_item;
render_mode blend_premul_alpha;

//const float PI = 3.14159265358979323846;
const vec2 CENTER = vec2(0.5, 0.5);
uniform float rotation = 0.0;
uniform bool is_flipped_x = false;
uniform bool is_flipped_y = false;
uniform bool is_flow_map = false;

vec2 rotateUV(vec2 uv, float rot) {
    float cosa = cos(rot);
    float sina = sin(rot);
    mat2 rotation_matrix = mat2(
        vec2(cosa, -sina),
        vec2(sina, cosa)
    );
	return uv * rotation_matrix;
}

vec2 rotate_around_center(vec2 uv, float rot) {
	return CENTER + rotateUV(uv - CENTER, rot);
}

vec2 flip(vec2 uv, bool flip_x, bool flip_y) {
	vec2 new_uv = uv;
	if (flip_x) {
		new_uv.x = 1.0 - new_uv.x;
	} else if (flip_y) {
		new_uv.y = 1.0 - new_uv.y;
	}
	return new_uv;
}

void fragment() {
	vec2 new_uv = flip(UV, is_flipped_x, is_flipped_y);
	new_uv = rotate_around_center(new_uv, rotation);
	vec4 pixel_color = texture(TEXTURE, new_uv);
	if (is_flow_map) {
		pixel_color.rg = flip(pixel_color.rg, is_flipped_x, is_flipped_y);
		pixel_color.rg = rotate_around_center(pixel_color.rg, rotation);
	}	
	COLOR = pixel_color;
}