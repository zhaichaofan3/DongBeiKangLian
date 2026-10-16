shader_type spatial;

// S23: soft, camera-readable mist bands. The alpha stays modest so actors
// remain legible while the bands separate the lake, rim and far mountains.
render_mode unshaded, cull_disabled, depth_draw_never;
uniform float environment_time = 0.0;

uniform vec4 mist_color : source_color = vec4(0.56, 0.68, 0.70, 1.0);
uniform float opacity = 0.16;
uniform float drift = 0.035;
varying vec3 mist_world_position;

void vertex() {
	 mist_world_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	float band = 0.5 + 0.5 * sin(mist_world_position.x * 0.055 + mist_world_position.z * 0.041 + environment_time * drift);
	float soft = (1.0 - smoothstep(0.2, 0.5, abs(UV.y - 0.5))) * (1.0 - smoothstep(0.25, 0.5, abs(UV.x - 0.5)));
	ALBEDO = mist_color.rgb;
	ALPHA = opacity * (0.60 + band * 0.40) * soft;
}
