shader_type canvas_item;

uniform vec2 center = vec2(0.5, 0.5);
uniform float spin_speed = 0.28;
uniform float swirl_strength = 0.12;
uniform float morph_strength = 0.018;
uniform float morph_speed = 1.15;
uniform float rotation_offset = 0.0;
// Keeps the mug outline crisp when UVs are pulled by the warp
uniform bool clip_to_shape = true;

vec2 coffee_uv(vec2 uv) {
	vec2 p = uv - center;
	float dist = length(p);
	float angle = atan(p.y, p.x);
	float t = TIME * morph_speed + rotation_offset;

	// Slow cup spin + stronger twist toward the rim
	float rim = smoothstep(0.0, 0.55, dist);
	float swirl = swirl_strength * rim * (sin(t * 0.65 + dist * 9.0) * 0.35 + 1.0);
	angle += t * spin_speed + swirl * dist;

	// Soft surface wobble
	vec2 wobble = vec2(
		sin(p.y * 14.0 + t * 1.25),
		cos(p.x * 13.0 + t * 1.05)
	) * morph_strength * (1.0 - dist * 0.85);

	p = vec2(cos(angle), sin(angle)) * dist;
	return clamp(p + center + wobble, vec2(0.001), vec2(0.999));
}

void fragment() {
	vec2 warped_uv = coffee_uv(UV);
	vec4 col = texture(TEXTURE, warped_uv);

	if (clip_to_shape) {
		col.a = min(col.a, texture(TEXTURE, UV).a);
	}

	COLOR = col;
}
