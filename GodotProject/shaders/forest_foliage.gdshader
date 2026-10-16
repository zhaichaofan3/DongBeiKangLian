shader_type spatial;
render_mode cull_disabled;

uniform vec4 shade_color : source_color = vec4(0.14, 0.23, 0.16, 1.0);
uniform vec4 sun_color : source_color = vec4(0.42, 0.46, 0.31, 1.0);
uniform float wind_strength = 0.1;
uniform float detail_wind = 1.0;
varying float leaf_variation;

void vertex() {
	vec3 world = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	float gust = sin(world.x * 0.16 + world.z * 0.11 + TIME * 0.8);
	float flutter = sin(world.z * 2.1 + world.x * 1.7 + TIME * 2.7);
	float weight = clamp(VERTEX.y * 0.16, 0.05, 1.0);
	VERTEX.x += (gust + flutter * 0.17 * detail_wind) * wind_strength * weight;
	VERTEX.z += cos(world.x * 0.15 + TIME * 0.6) * wind_strength * weight * 0.5;
	leaf_variation = COLOR.r;
}

void fragment() {
	ALBEDO = mix(shade_color.rgb, sun_color.rgb, leaf_variation);
	ROUGHNESS = 0.96;
	SPECULAR = 0.12;
	BACKLIGHT = ALBEDO * 0.12;
}
