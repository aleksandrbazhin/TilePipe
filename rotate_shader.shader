shader_type canvas_item;

render_mode unshaded;

//const float PI = 3.14159265358979323846;
//uniform vec2 center = vec2(16, 16);
uniform vec2 center = vec2(0.5, 0.5);
uniform float rotation = 0.0;

vec2 rotateUV(vec2 uv, float rot) {
    float cosa = cos(rot);
    float sina = sin(rot);
    mat2 rotation_matrix = mat2(
        vec2(cosa, -sina),
        vec2(sina, cosa)
    );
//   mat2 rotation_matrix = mat2(
//        vec2(sina, -cosa),
//        vec2(cosa, sina)
//    );

	return uv * rotation_matrix;
}


void fragment() {
//	vec2 tilemap_uv = UV - center; 
	COLOR = texture(TEXTURE, center + rotateUV(UV - center, rotation));
}