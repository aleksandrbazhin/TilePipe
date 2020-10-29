shader_type canvas_item;
render_mode blend_premul_alpha;

const vec2 CENTER = vec2(0.5, 0.5);

uniform sampler2D overlay_texture_1;
uniform sampler2D overlay_texture_2;
uniform sampler2D overlay_texture_4;
uniform sampler2D overlay_texture_8;
uniform sampler2D overlay_texture_16;
uniform sampler2D overlay_texture_32;
uniform sampler2D overlay_texture_64;
uniform sampler2D overlay_texture_128;

uniform float rotation_1;
uniform float rotation_2;
uniform float rotation_4;
uniform float rotation_8;
uniform float rotation_16;
uniform float rotation_32;
uniform float rotation_64;
uniform float rotation_128;

uniform float overlay_rate;
uniform float overlap;
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

vec4 get_color_from_rotated(vec2 uv, vec4 bg_color, sampler2D overlay,float rotation, bool is_overlap) {
	vec4 pixel_color;
	vec2 new_uv = rotate_around_center(uv, rotation);
	pixel_color =  texture(overlay, new_uv);
	if (is_overlap && pixel_color.a == 0.0) {
		pixel_color =  mix(pixel_color, bg_color, 1.0);
//		pixel_color = vec4(1, 1, 1, 1);
	}
	if (is_flow_map) {
		pixel_color.rg = rotate_around_center(pixel_color.rg, rotation);
	}
	return pixel_color;
}

void fragment() {
	bool out_x_plus = UV.x > 1.0 - overlay_rate;
	bool out_x_minus = UV.x < overlay_rate;
	bool out_y_plus = UV.y > 1.0 - overlay_rate;
	bool out_y_minus = UV.y < overlay_rate;
	float plus_overlap = (1.0 - overlay_rate) + overlay_rate * overlap * 2.0;
	float minus_overlap = overlay_rate - overlay_rate * overlap * 2.0;
	if (out_x_plus) {
		if (out_y_plus) {
			COLOR = get_color_from_rotated(UV, texture(TEXTURE, UV), overlay_texture_8, rotation_8, plus_overlap > UV.x && plus_overlap > UV.y);
		} else if (out_y_minus) {
			COLOR = get_color_from_rotated(UV, texture(TEXTURE, UV), overlay_texture_2, rotation_2, plus_overlap > UV.x && minus_overlap < UV.y);
		} else {
			COLOR = get_color_from_rotated(UV, texture(TEXTURE, UV),  overlay_texture_4, rotation_4, plus_overlap > UV.x);
		}
	} else if (out_x_minus) {
		if (out_y_plus) {
			COLOR = get_color_from_rotated(UV, texture(TEXTURE, UV), overlay_texture_32, rotation_32, minus_overlap < UV.x && plus_overlap > UV.y);
		} else if (out_y_minus) {
			COLOR = get_color_from_rotated(UV, texture(TEXTURE, UV), overlay_texture_128, rotation_128, minus_overlap < UV.x && minus_overlap < UV.y);
		} else {
			COLOR = get_color_from_rotated(UV, texture(TEXTURE, UV), overlay_texture_64, rotation_64, minus_overlap < UV.x);
		}
	} else {
		if (out_y_plus) {
			COLOR = get_color_from_rotated(UV, texture(TEXTURE, UV), overlay_texture_16, rotation_16, plus_overlap > UV.y);
		} else if (out_y_minus) {
			COLOR = get_color_from_rotated(UV, texture(TEXTURE, UV), overlay_texture_1, rotation_1, minus_overlap < UV.y);
		} else {
			COLOR = texture(TEXTURE, UV);
		}
	}
}