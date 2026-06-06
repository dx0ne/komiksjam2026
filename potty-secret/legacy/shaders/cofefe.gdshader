shader_type canvas_item;
//I DONT OWN THIS i just took it directly from balatros source code teehee
//and then converted it into godots shader language myself
//shoutouts localthunk, buy balatro

uniform bool polar_coordinates = false;
uniform vec2 polar_center = vec2(0.5);
uniform float polar_zoom = 1.;
uniform float polar_repeat = 1.;

uniform highp float spin_rotation;
uniform highp float spin_speed = 1;
uniform highp vec2 offset = vec2(0., 0.);
uniform highp vec4 colour_1 : source_color = vec4(0.24, 0.14, 0.09, 1.0);
uniform highp vec4 colour_2 : source_color = vec4(0.42, 0.27, 0.14, 1.0);
uniform highp vec4 colour_3 : source_color = vec4(0.65, 0.49, 0.32, 1.0);
uniform highp float contrast = 2.;
uniform highp float spin_amount = 0.36;
uniform highp float pixel_filter = 700.;
// false = procedural swirl clipped to sprite alpha; true = distort texture UVs
uniform bool morph_texture = false;
#define SPIN_EASE 1.0


// Shared swirl + paint distortion. Returns centered UV after distortion (pre-*30 scale).
vec2 distort_centered_uv(vec2 screenSize, highp vec2 uv, out highp float paint_res) {
	highp float uv_len = length(uv);

	highp float speed = (spin_rotation * SPIN_EASE * 0.2) + TIME * spin_speed * SPIN_EASE * 0.2 + 302.2;
	highp float new_pixel_angle = atan(uv.y, uv.x) + speed - SPIN_EASE * 20. * (spin_amount * uv_len + (1. - spin_amount));
	vec2 mid = (screenSize / length(screenSize)) / 2.0;
	uv = vec2(uv_len * cos(new_pixel_angle) + mid.x, uv_len * sin(new_pixel_angle) + mid.y) - mid;

	uv *= 30.;
	speed = TIME * spin_speed;
	highp vec2 uv2 = vec2(uv.x + uv.y);

	for (int i = 0; i < 5; i++) {
		uv2 += sin(max(uv.x, uv.y)) + uv;
		uv += 0.5 * vec2(cos(5.1123314 + 0.353 * uv2.y + speed * 0.131121), sin(uv2.x - 0.113 * speed));
		uv -= 1.0 * cos(uv.x + uv.y) - 1.0 * sin(uv.x * 0.711 - uv.y);
	}

	highp float contrast_mod = (0.25 * contrast + 0.5 * spin_amount + 1.2);
	paint_res = min(2., max(0., length(uv) * 0.035 * contrast_mod));
	return uv / 30.;
}


vec4 paint_from_res(highp float paint_res) {
	highp float contrast_mod = (0.25 * contrast + 0.5 * spin_amount + 1.2);
	highp float c1p = max(0., 1. - contrast_mod * abs(1. - paint_res));
	highp float c2p = max(0., 1. - contrast_mod * abs(paint_res));
	highp float c3p = 1. - min(1., c1p + c2p);
	return (0.3 / contrast) * colour_1 + (1. - 0.3 / contrast) * (colour_1 * c1p + colour_2 * c2p + vec4(c3p * colour_3.rgb, c3p * colour_1.a));
}


vec2 screen_coords_to_centered(vec2 screenSize, vec2 screen_coords, bool pixelate) {
	highp float pixel_size = length(screenSize.xy) / pixel_filter;
	if (pixelate) {
		screen_coords = floor(screen_coords * (1. / pixel_size)) * pixel_size;
	}
	return (screen_coords - 0.5 * screenSize.xy) / length(screenSize.xy) - offset;
}


vec2 centered_to_uv(vec2 screenSize, vec2 centered) {
	return (centered + offset) * length(screenSize.xy) / screenSize.xy + 0.5;
}


vec4 procedural_swirl(vec2 screenSize, vec2 screen_coords) {
	highp float paint_res;
	vec2 centered = screen_coords_to_centered(screenSize, screen_coords, true);
	centered = distort_centered_uv(screenSize, centered, paint_res);
	return paint_from_res(paint_res);
}


vec2 warped_texture_uv(vec2 screenSize, vec2 screen_coords) {
	highp float paint_res;
	vec2 centered = screen_coords_to_centered(screenSize, screen_coords, false);
	centered = distort_centered_uv(screenSize, centered, paint_res);
	return centered_to_uv(screenSize, centered);
}


vec2 polar_coords(vec2 uv, vec2 center, float zoom, float repeat) {
	vec2 dir = uv - center;
	float radius = length(dir) * 2.0;
	float angle = atan(dir.y, dir.x) * 1.0 / (PI * 2.0);
	return mod(vec2(radius * zoom, angle * repeat), 1.0);
}


void fragment() {
	vec2 tex_size = vec2(textureSize(TEXTURE, 0));
	vec2 uv = UV;
	vec2 coords = uv * tex_size;

	if (polar_coordinates) {
		uv = polar_coords(uv, polar_center, polar_zoom, polar_repeat);
		coords = uv * tex_size;
	}

	float shape_alpha = texture(TEXTURE, UV).a;

	if (morph_texture) {
		vec2 sample_uv = warped_texture_uv(tex_size, coords);
		vec4 warped = texture(TEXTURE, sample_uv);
		COLOR = vec4(warped.rgb, shape_alpha);
	} else {
		vec4 swirl = procedural_swirl(tex_size, coords);
		COLOR = vec4(swirl.rgb, swirl.a * shape_alpha);
	}
}
