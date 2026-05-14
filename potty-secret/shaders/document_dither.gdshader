shader_type canvas_item;

uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_nearest;
uniform sampler2D dither_texture : repeat_enable, filter_nearest;

uniform int u_bit_depth : hint_range(2, 128, 1) = 6;
uniform float u_contrast : hint_range(0.2, 3.0, 0.01) = 1.1;
uniform float u_offset : hint_range(-0.5, 0.5, 0.01) = 0.0;
uniform int u_dither_size : hint_range(1, 8, 1) = 2;
uniform float u_intensity : hint_range(0.0, 1.0, 0.01) = 0.7;
uniform float u_tint_strength : hint_range(0.0, 1.0, 0.01) = 0.3;

uniform vec4 shadow_color : source_color = vec4(0.31, 0.25, 0.15, 1.0);
uniform vec4 mid_color : source_color = vec4(0.66, 0.55, 0.34, 1.0);
uniform vec4 paper_color : source_color = vec4(0.96, 0.88, 0.66, 1.0);

const vec3 LUMINANCE = vec3(0.2126, 0.7152, 0.0722);

vec3 paper_palette(float luminance) {
	if (luminance < 0.5) {
		return mix(shadow_color.rgb, mid_color.rgb, luminance * 2.0);
	}

	return mix(mid_color.rgb, paper_color.rgb, (luminance - 0.5) * 2.0);
}

void fragment() {
	vec2 screen_size = vec2(textureSize(screen_texture, 0));
	vec2 dither_cell = floor(SCREEN_UV * screen_size / float(u_dither_size));
	vec2 screen_sample_uv = ((dither_cell + 0.5) * float(u_dither_size)) / screen_size;
	vec3 screen_col = textureLod(screen_texture, screen_sample_uv, 0.0).rgb;

	vec3 adjusted_col = clamp((screen_col - 0.5 + u_offset) * u_contrast + 0.5, 0.0, 1.0);

	vec2 dither_uv = (dither_cell + 0.5) / vec2(textureSize(dither_texture, 0));
	float threshold = texture(dither_texture, dither_uv).r - 0.5;
	float levels = max(float(u_bit_depth) - 1.0, 1.0);
	vec3 dithered_col = adjusted_col + threshold / levels;
	vec3 quantized_col = round(clamp(dithered_col, 0.0, 1.0) * levels) / levels;

	float lum = dot(quantized_col, LUMINANCE);
	vec3 tinted_col = mix(quantized_col, paper_palette(lum), u_tint_strength);

	COLOR = vec4(mix(screen_col, tinted_col, u_intensity), 1.0);
}
