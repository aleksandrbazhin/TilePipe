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

uniform int rotation_1_key;
uniform int rotation_2_key;
uniform int rotation_4_key;
uniform int rotation_8_key;
uniform int rotation_16_key;
uniform int rotation_32_key;
uniform int rotation_64_key;
uniform int rotation_128_key;


const mat2 rotate_matrix_0 = mat2(vec2(1.0, 0.0), vec2(0.0, 1.0));
const mat2 rotate_matrix_1 = mat2(vec2(0.0, 1.0), vec2(-1.0, 0.0));
const mat2 rotate_matrix_2 = mat2(vec2(-1.0, 0.0), vec2(0.0, -1.0));
const mat2 rotate_matrix_3 = mat2(vec2(0.0, -1.0), vec2(1.0, 0.0));


uniform float overlay_rate;
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

vec2 rotateUV_by_key(vec2 uv, int key) {
	if (key == 0) {
		return uv * rotate_matrix_0;
	} else if (key == 1) {
		return uv * rotate_matrix_1;
	} else if (key == 2) {
		return uv * rotate_matrix_2;
	} else if (key == 3) {
		return uv * rotate_matrix_3;
	}
}

vec2 rotate_around_center(vec2 uv, float rot) {
	return CENTER + rotateUV(uv - CENTER, rot);
}

vec2 rotate_around_center_by_key(vec2 uv, int rotation_key) {
	return CENTER + rotateUV_by_key(uv - CENTER, rotation_key);
}


vec4 get_color_from_rotated_by_key(vec2 uv, vec4 bg_color, sampler2D overlay, int rotation_key) {
	vec4 pixel_color;
	vec2 new_uv = rotate_around_center_by_key(uv, rotation_key);
	pixel_color =  mix(bg_color, texture(overlay, new_uv), 1.0);
	if (is_flow_map) {
		pixel_color.rg = rotate_around_center_by_key(pixel_color.rg, rotation_key);
	}
	return pixel_color;
}

vec4 get_color_from_rotated(vec2 uv, vec4 bg_color, sampler2D overlay, float rotation) {
	vec4 pixel_color;
	vec2 new_uv = rotate_around_center(uv, rotation);
	pixel_color =  mix(bg_color, texture(overlay, new_uv), 1.0);
	if (is_flow_map) {
		pixel_color.rg = rotate_around_center(pixel_color.rg, rotation);
	}
	return pixel_color;
}


void fragment() {
	COLOR = texture(TEXTURE, UV);
//	if (UV.y <= overlay_rate) {
//		COLOR = get_color_from_rotated(UV, COLOR, overlay_texture_1, rotation_1);
//	} else if (UV.y >= 1.0 - overlay_rate) {
//		COLOR = get_color_from_rotated(UV, COLOR, overlay_texture_16, rotation_16);
//	} else if (UV.x >= 1.0 - overlay_rate) {
//		COLOR = get_color_from_rotated(UV, COLOR, overlay_texture_4, rotation_4);
//	} else if (UV.x <= overlay_rate) {
//		COLOR = get_color_from_rotated(UV, COLOR, overlay_texture_64, rotation_64);
//	}
//
////	float from_center = distance(UV, CENTER);
//	if (UV.y <= overlay_rate && UV.x >= 1.0 - overlay_rate) {
//		COLOR = get_color_from_rotated(UV, COLOR, overlay_texture_2, rotation_2);
//	} else if (UV.y >= 1.0 - overlay_rate && UV.x >= 1.0 - overlay_rate) {
//		COLOR = get_color_from_rotated(UV, COLOR, overlay_texture_8, rotation_8);
//	} else if (UV.y >= 1.0 - overlay_rate && UV.x <= overlay_rate) {
//		COLOR = get_color_from_rotated(UV, COLOR, overlay_texture_32, rotation_32);
//	} else if (UV.y <= overlay_rate && UV.x <= overlay_rate) {
//		COLOR = get_color_from_rotated(UV, COLOR, overlay_texture_128, rotation_128);
//	}
	if (UV.y <= overlay_rate) {
		COLOR = get_color_from_rotated_by_key(UV, COLOR, overlay_texture_1, rotation_1_key);
	} else if (UV.y >= 1.0 - overlay_rate) {
		COLOR = get_color_from_rotated_by_key(UV, COLOR, overlay_texture_16, rotation_16_key);
	} else if (UV.x >= 1.0 - overlay_rate) {
		COLOR = get_color_from_rotated_by_key(UV, COLOR, overlay_texture_4, rotation_4_key);
	} else if (UV.x <= overlay_rate) {
		COLOR = get_color_from_rotated_by_key(UV, COLOR, overlay_texture_64, rotation_64_key);
	}
	
//	float from_center = distance(UV, CENTER);
	if (UV.y <= overlay_rate && UV.x >= 1.0 - overlay_rate) {
		COLOR = get_color_from_rotated_by_key(UV, COLOR, overlay_texture_2, rotation_2_key);
	} else if (UV.y >= 1.0 - overlay_rate && UV.x >= 1.0 - overlay_rate) {
		COLOR = get_color_from_rotated_by_key(UV, COLOR, overlay_texture_8, rotation_8_key);
	} else if (UV.y >= 1.0 - overlay_rate && UV.x <= overlay_rate) {
		COLOR = get_color_from_rotated_by_key(UV, COLOR, overlay_texture_32, rotation_32_key);
	} else if (UV.y <= overlay_rate && UV.x <= overlay_rate) {
		COLOR = get_color_from_rotated_by_key(UV, COLOR, overlay_texture_128, rotation_128_key);
	}
}