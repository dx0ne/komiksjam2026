shader_type canvas_item;

uniform sampler2D screen_texture : hint_screen_texture, filter_linear;
uniform float brighten : hint_range(0.0, 1.0, 0.01) = 0.0;

// Toggle / weight each pass (0 = off, 1 = full) — tweak in Inspector → Material → Shader Parameters
uniform float lighten_mix : hint_range(0.0, 1.0, 0.01) = 1.0;
uniform float screen_mix : hint_range(0.0, 1.0, 0.01) = 0.55;
uniform float luma_lift : hint_range(0.0, 1.0, 0.01) = 0.55;
uniform float luma_boost : hint_range(0.0, 0.3, 0.01) = 0.05;
uniform float sat_boost : hint_range(0.0, 1.5, 0.01) = 0.4;
uniform float screen_push : hint_range(0.0, 0.5, 0.01) = 0.12;

const vec3 LUMINANCE = vec3(0.299, 0.587, 0.114);

vec3 blend_screen(vec3 base, vec3 blend) {
	return 1.0 - (1.0 - base) * (1.0 - blend);
}

vec3 blend_lighten(vec3 base, vec3 blend) {
	return max(base, blend);
}

void fragment() {
	vec3 base = texture(screen_texture, SCREEN_UV).rgb;
	float t = brighten;
	float active = step(0.0001, t);

	float luma = dot(base, LUMINANCE);
	vec3 chroma = base - vec3(luma);
	float lifted_luma = luma + t * (1.0 - luma) * luma_lift + t * luma_boost;
	vec3 vivid_layer = vec3(lifted_luma) + chroma * (1.0 + t * sat_boost);

	vec3 after_lighten = blend_lighten(base, vivid_layer);
	vec3 with_lighten = mix(base, after_lighten, lighten_mix * active);

	vec3 screen_layer = base + vec3(t * screen_push);
	vec3 after_screen = blend_screen(with_lighten, screen_layer);
	vec3 with_both = mix(with_lighten, after_screen, screen_mix * active);

	vec3 result = mix(base, with_both, active);
	COLOR = vec4(clamp(result, 0.0, 1.0), 1.0);
}
