shader_type spatial;
render_mode diffuse_burley, cull_back;

float hash21(vec2 p) {
	p = fract(p * vec2(123.34, 456.21));
	p += dot(p, p + 45.32);
	return fract(p.x * p.y);
}

void fragment() {
	vec2 cell = floor(UV * vec2(28.0, 9.0));
	float grain = hash21(cell);
	float edge = smoothstep(0.04, 0.30, UV.y) * (1.0 - smoothstep(0.72, 0.98, UV.y));
	vec3 cold = vec3(0.63, 0.76, 0.80);
	vec3 light = vec3(0.88, 0.93, 0.93);
	ALBEDO = mix(cold, light, 0.50 + grain * 0.32 + edge * 0.10);
	ROUGHNESS = 0.96;
}
