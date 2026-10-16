shader_type canvas_item;
render_mode unshaded;
uniform vec2 inward = vec2(0.0, 1.0);
void fragment() {
	float distance_in = dot(UV, max(inward, vec2(0.0))) + dot(vec2(1.0) - UV, max(-inward, vec2(0.0)));
	COLOR.a *= pow(1.0 - smoothstep(0.0, 1.0, distance_in), 1.5);
}
