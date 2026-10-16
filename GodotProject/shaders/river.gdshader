shader_type spatial;

uniform float wave_detail = 1.0;
uniform vec2 current_direction = vec2(0.0, 1.0);
varying vec3 river_position;

void vertex() {
	river_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	vec2 p = river_position.xz - current_direction * TIME * 0.85;
	float wave_a = sin(p.x * 0.71 + p.y * 1.13 + TIME * 0.65);
	float wave_b = sin(p.x * 2.1 - p.y * 0.53 + TIME * 0.91);
	float wave_c = sin(p.x * 8.0 + p.y * 3.5 - TIME * 1.35) * wave_detail;
	NORMAL_MAP = normalize(vec3(wave_a * 0.08 + wave_c * 0.018, wave_b * 0.06, 1.0)) * 0.5 + 0.5;
	float fresnel = pow(1.0 - max(dot(NORMAL, VIEW), 0.0), 3.0);
	vec3 deep = vec3(0.105, 0.18, 0.18);
	vec3 sky_reflection = vec3(0.39, 0.47, 0.48);
	float ribbons = smoothstep(0.88, 1.0, wave_a * 0.55 + wave_b * 0.45) * 0.06;
	ALBEDO = mix(deep, sky_reflection, 0.24 + fresnel * 0.62) + ribbons;
	ROUGHNESS = 0.48;
	METALLIC = 0.05;
	SPECULAR = 0.28;
}
