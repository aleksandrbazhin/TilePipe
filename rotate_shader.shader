shader_type canvas_item;
render_mode blend_premul_alpha;

//const float PI = 3.14159265358979323846;
const vec2 center = vec2(0.5, 0.5);
uniform float rotation = 0.0;
uniform bool is_flipped_x = false;
uniform bool is_flipped_y = false;
uniform bool is_normal_map = false;

vec2 rotateUV(vec2 uv, float rot) {
    float cosa = cos(rot);
    float sina = sin(rot);
    mat2 rotation_matrix = mat2(
        vec2(cosa, -sina),
        vec2(sina, cosa)
    );
	return uv * rotation_matrix;
}

void fragment() {
//	vec2 tilemap_uv = UV - center; 
	vec2 rotated_UV = UV;
	if (is_flipped_x) {
		rotated_UV.x = 1.0 - rotated_UV.x;
	} else if (is_flipped_y) {
		rotated_UV.y = 1.0 - rotated_UV.y;
	}
	rotated_UV = center + rotateUV(rotated_UV - center, rotation);
	COLOR = texture(TEXTURE, rotated_UV);
}