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

//uniform float overlay_rotation;
//const float PI = 3.14159265358979323846;
//uniform float rotation = 0.0;

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

//vec4 mix_overlay() {
//	return 
//}

void fragment() {
	COLOR = texture(TEXTURE, UV);
	
	
	if (UV.y < overlay_rate) {
		vec2 new_uv = rotate_around_center(UV, rotation_1);
		COLOR = mix(COLOR, texture(overlay_texture_1, new_uv), 1.0);
	} else if (UV.y > 1.0 - overlay_rate) {
		vec2 new_uv = rotate_around_center(UV, rotation_16);
		COLOR = mix(COLOR, texture(overlay_texture_16, new_uv), 1.0);
	} else if (UV.x > 1.0 - overlay_rate) {
		vec2 new_uv = rotate_around_center(UV, rotation_4);
		COLOR = mix(COLOR, texture(overlay_texture_4, new_uv), 1.0);
	} else if (UV.x < overlay_rate) {
		vec2 new_uv = rotate_around_center(UV, rotation_64);
		COLOR = mix(COLOR, texture(overlay_texture_64, new_uv), 1.0);
	}
	
//	float from_center = distance(UV, CENTER);
	if (UV.y < overlay_rate && UV.x > 1.0 - overlay_rate) {
		vec2 new_uv = rotate_around_center(UV, rotation_2);
		COLOR = mix(COLOR, texture(overlay_texture_2, new_uv), 1.0);
	} else if (UV.y > 1.0 - overlay_rate && UV.x > 1.0 - overlay_rate) {
		vec2 new_uv = rotate_around_center(UV, rotation_8);
		COLOR = mix(COLOR, texture(overlay_texture_8, new_uv), 1.0);
	} else if (UV.y > 1.0 - overlay_rate && UV.x < overlay_rate) {
		vec2 new_uv = rotate_around_center(UV, rotation_32);
		COLOR = mix(COLOR, texture(overlay_texture_32, new_uv), 1.0);
	} else if (UV.y < overlay_rate && UV.x < overlay_rate) {
		vec2 new_uv = rotate_around_center(UV, rotation_128);
		COLOR = mix(COLOR, texture(overlay_texture_128, new_uv), 1.0);
	}
//	} else {
//		COLOR = texture(TEXTURE, UV);
//	}
//	vec4 overlay_color_2 = texture(overlay_texture_2, new_uv);
//	if (distance(UV, CENTER) > overlay_rate) {
//		COLOR = mix(COLOR, overlay_color_2, 0.5);
//	}
//	vec2 new_uv = flip(UV, is_flipped_x, is_flipped_y);
//	new_uv = rotate_around_center(new_uv, rotation);
//	vec4 pixel_color = texture(TEXTURE, new_uv);
//	if (is_flow_map) {
//		pixel_color.rg = flip(pixel_color.rg, is_flipped_x, is_flipped_y);
//		pixel_color.rg = rotate_around_center(pixel_color.rg, -rotation);
//	}	
//	COLOR = pixel_color;
}