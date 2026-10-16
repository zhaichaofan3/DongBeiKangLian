shader_type spatial;
render_mode shadows_disabled;
uniform float environment_time = 0.0;

// S23: a restrained animated surface for the artistic crater lake.
// The mesh remains opaque so the deep-blue silhouette stays stable in the
// GL Compatibility renderer used by the project.
varying vec3 lake_world_position;

void vertex() {
	 lake_world_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	vec2 p = lake_world_position.xz;
	float warp = sin(p.y * 0.11 + environment_time * 0.06) * 1.7 + sin(p.x * 0.09) * 0.9;
	float broad = sin(p.x * 0.19 + p.y * 0.27 + warp + environment_time * 0.23);
	float fine = sin(p.x * 0.73 - p.y * 0.41 + sin(p.x * 0.28 + p.y * 0.19) * 2.5 + environment_time * 0.47);
	float ripple = sin(p.x * 2.6 + p.y * 1.9 - environment_time * 0.82);
	float fresnel = pow(1.0 - max(dot(NORMAL, VIEW), 0.0), 3.0);
	vec3 deep = vec3(0.008, 0.045, 0.105);
	vec3 blue = vec3(0.035, 0.18, 0.31);
	vec3 reflection = vec3(0.30, 0.47, 0.54);
	float shimmer = clamp(0.5 + broad * 0.12 + fine * 0.06 + ripple * 0.025, 0.0, 1.0);
	ALBEDO = mix(deep, blue, 0.45 + shimmer * 0.22);
	ALBEDO = mix(ALBEDO, reflection, fresnel * 0.42);
	ROUGHNESS = 0.32;
	METALLIC = 0.08;
	SPECULAR = 0.62;
	NORMAL_MAP = normalize(vec3(fine * 0.04 + ripple * 0.018, broad * 0.035, 1.0)) * 0.5 + 0.5;
}
