shader_type spatial;
render_mode cull_back;

uniform sampler2D ground_diffuse : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D road_diffuse : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D road_normal : hint_normal, filter_linear_mipmap_anisotropic, repeat_enable;
uniform bool is_road = false;
varying vec2 ground_position;

void vertex() {
	ground_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xz;
}

void fragment() {
	vec3 earth = texture(ground_diffuse, ground_position * 0.26).rgb;
	float earth_value = dot(earth, vec3(0.299, 0.587, 0.114));
	earth = mix(vec3(earth_value), earth, 0.35) * vec3(0.84, 0.79, 0.69);
	vec3 tracks = texture(road_diffuse, ground_position * 0.26).rgb;
	float track_value = dot(tracks, vec3(0.299, 0.587, 0.114));
	tracks = mix(vec3(track_value), tracks, 0.12) * vec3(1.12, 1.06, 0.93);
	float edge_noise = sin(ground_position.x * 3.7 + ground_position.y * 4.3) * 0.018;
	float road_weight = is_road ? smoothstep(0.0, 0.12, UV.x + edge_noise) * (1.0 - smoothstep(0.88, 1.0, UV.x + edge_noise)) : 0.0;
	ALBEDO = mix(earth, tracks, road_weight);
	NORMAL_MAP = texture(road_normal, ground_position * 0.26).rgb;
	NORMAL_MAP_DEPTH = 0.22;
	ROUGHNESS = 0.96;
	SPECULAR = 0.18;
}
