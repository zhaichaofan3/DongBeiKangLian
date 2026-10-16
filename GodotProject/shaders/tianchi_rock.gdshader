shader_type spatial;
render_mode diffuse_burley;

uniform sampler2D rock_color : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform vec3 basalt : source_color = vec3(0.30, 0.33, 0.32);
uniform vec3 lichen : source_color = vec3(0.36, 0.39, 0.29);
uniform bool alpine = true;
varying vec3 world_pos;
varying vec3 world_normal;

float hash(vec3 p) {
    return fract(sin(dot(p, vec3(127.1, 311.7, 74.7))) * 43758.5453);
}

float noise3(vec3 p) {
    vec3 i = floor(p);
    vec3 f = fract(p);
    f = f * f * (3.0 - 2.0 * f);
    return mix(mix(mix(hash(i), hash(i + vec3(1,0,0)), f.x), mix(hash(i + vec3(0,1,0)), hash(i + vec3(1,1,0)), f.x), f.y), mix(mix(hash(i + vec3(0,0,1)), hash(i + vec3(1,0,1)), f.x), mix(hash(i + vec3(0,1,1)), hash(i + vec3(1,1,1)), f.x), f.y), f.z);
}

void vertex() {
    world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
    world_normal = normalize(MODEL_NORMAL_MATRIX * NORMAL);
}

void fragment() {
    vec3 w = pow(abs(world_normal), vec3(4.0));
    w /= max(w.x + w.y + w.z, 0.001);
    vec3 p = world_pos * 0.34;
    vec3 stone = texture(rock_color, p.zy).rgb * w.x + texture(rock_color, p.xz).rgb * w.y + texture(rock_color, p.xy).rgb * w.z;
    stone = mix(vec3(dot(stone, vec3(0.299, 0.587, 0.114))), stone, 0.12);
    float broad = noise3(world_pos * 0.16);
    float strata = noise3(vec3(world_pos.x * 0.12, world_pos.y * 0.60 + broad * 2.0, world_pos.z * 0.12));
    float erosion = noise3(vec3(world_pos.x * 0.32, world_pos.y * 0.07, world_pos.z * 0.32));
    float up = smoothstep(0.60, 0.91, world_normal.y);
    float moss = smoothstep(0.42, 0.76, broad) * up;
    vec3 tint = mix(basalt, lichen, moss * 0.70) * mix(0.80, 1.15, broad);
    vec3 result = tint * mix(vec3(0.88), stone * 2.4, 0.58) * mix(0.80, 1.14, strata) * mix(0.75, 1.16, smoothstep(0.28, 0.72, erosion));
    float snow = alpine ? smoothstep(36.0, 43.0, world_pos.y + broad * 4.5) * up * smoothstep(0.3, 0.7, broad) : 0.0;
    ALBEDO = mix(result, vec3(0.76, 0.81, 0.80), snow * 0.75);
    ROUGHNESS = 0.96;
    SPECULAR = 0.12;
    vec3 view_pos = (VIEW_MATRIX * vec4(world_pos, 1.0)).xyz;
    float bump = dot(stone, vec3(0.333));
    vec3 dx = dFdx(view_pos);
    vec3 dy = dFdy(view_pos);
    vec3 r1 = cross(dy, NORMAL);
    vec3 r2 = cross(NORMAL, dx);
    float det = dot(dx, r1);
    vec3 gradient = sign(det) * (dFdx(bump) * r1 + dFdy(bump) * r2);
    NORMAL = normalize(max(abs(det), 0.000001) * NORMAL - gradient * 0.018);
}
