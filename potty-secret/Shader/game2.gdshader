shader_type canvas_item;
group_uniforms Main;
/**
0 = Texture: For use with Sprite2Ds, TextureRects, and Meshes
1 = Screen: For use with ColorRect
*/
uniform int texture_mode : hint_range(0, 1) = 0;
/**
0 = Normal: No alpha change
1 = Alpha black: Outputs alpha as black
2 = Alpha cut: Cuts textures as a mask. Use within CanvasGroup node.
*/
uniform int alpha_mode : hint_range(0, 2) = 0;
group_uniforms;

uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, repeat_disable, filter_nearest;

// This file relies on a quantize shader include file.
// For compatibility on this site, it's included all in one file below here.
//#include "res://shaders/quantize.gdshaderinc"
//#include "res://shaders/dither.gdshaderinc"
//#include "res://shaders/adjustment.gdshaderinc"
//#include "res://shaders/palette.gdshaderinc"

// quantize.gdshaderinc

group_uniforms Quantization;
/**Pixel resolution scale (0 is bypass)*/
uniform int quantize_size : hint_range(0,100) = 1;
/**Pixels are snapped based on world coordinates vs local coordinates.*/
uniform bool snap_to_world;
/**Auto-scales the quantize size when zoom is < 1, preventing subpixel artifacts*/
uniform bool limit_subpixels = true;
group_uniforms;

varying mat2 v_model_matrix;
varying vec2 v_model_tr;
varying mat2 v_alt_matrix;
varying vec2 v_alt_tr;
varying vec2 v_vertex;
varying flat int v_quant_size;
varying flat vec4 v_texture_data;

const float EPSILON = 0.0001;

int getQuantizeSize(float in_zoom) {
    int q_size = quantize_size;

    if (limit_subpixels && in_zoom < 1.) {
        q_size = int(round(float(quantize_size) * (1. / in_zoom)));
    }

    return q_size;
}

vec2 _snap(vec2 in_uv, float in_q_size) {
    return (floor(in_uv / in_q_size) + 0.5) * in_q_size;
}

vec4 getQuantizeScreenUV(vec2 in_screen_uv, vec2 screen_pixel_size) {
    vec4 result;

    if (v_quant_size == 0) {
        result.xy = in_screen_uv;
        result.zw = v_model_matrix * v_vertex + v_model_tr;
        return result;
    }

    if (snap_to_world) {
        vec2 uv = v_model_matrix * v_vertex + v_model_tr;
        result.zw = uv + EPSILON;
        uv = _snap(uv, float(v_quant_size));
        uv = v_alt_matrix * uv + v_alt_tr;
        uv = uv * 0.5 + 0.5;
        result.xy = uv;
        return result;
    } else {
        vec2 origin_uv = v_texture_data.xy;
        vec2 quant_pixel_size = screen_pixel_size * v_texture_data.zw;
        vec2 uv = in_screen_uv - origin_uv;
        uv = (floor(uv / quant_pixel_size) + 0.5) * quant_pixel_size;

        uv = uv + origin_uv;
        vec2 clipXY = uv * 2.0 - 1.;
        vec2 world_pos = v_alt_matrix * clipXY + v_alt_tr;
        result.zw = world_pos + EPSILON;
        result.xy = uv;
        return result;
    }
}

vec4 getQuantizeTextureUV(vec2 in_uv) {
    vec4 result;
    vec2 texture_size = v_texture_data.xy;
    vec2 flip = vec2(dFdx(in_uv).x < 0. ? 1. : 0., dFdy(in_uv).y < 0. ? 1. : 0.);

    if (v_quant_size == 0) {
        result.xy = in_uv;
        result.zw = v_model_matrix * (in_uv * texture_size) + v_model_tr;
        return result;
    }

    vec2 offset;
    float q = float(v_quant_size);
    vec2 uv = in_uv;
    uv = mix(uv, 1.0 - uv, flip);

    if (snap_to_world) {
        vec2 inv_texture_size = 1. / texture_size;
        offset = v_vertex * inv_texture_size;
        offset = uv - offset;
        uv -= offset;

        uv *= texture_size;
        uv = v_model_matrix * uv + v_model_tr;
        result.zw = uv;
        uv = _snap(uv, q);
        uv = v_alt_matrix * uv + v_alt_tr;
        uv *= inv_texture_size;

        uv = offset + uv;
    } else {
        texture_size *= vec2(v_model_matrix[0][0], v_model_matrix[1][1]);
        uv *= texture_size;
        result.zw = uv;
        uv = _snap(uv, q);
        uv /= texture_size;
    }

    uv = mix(uv, 1.0 - uv, flip);
    result.xy = uv + EPSILON;
    return result;
}

// end quantize.gdshaderinc

// dither.gdshaderinc

group_uniforms Dithering;
/**Turns the dithering on or off.*/
uniform bool dither_enabled = false;
/**
The Bayer matrix pattern to use
1 -> 2x2, 2 -> 4x4, 3 -> 8x8
*/
uniform int dither_pattern : hint_range(0, 3) = 1;
/**
Specifies the number of times each color channel should be split.
The higher the number the more colors are allowed. (not applicable if a palette is used)
1 is 3bpp or 8 colors, 2 is 4bpp or 16 colors, etc.
*/
uniform int levels : hint_range(1, 128) = 2;
group_uniforms;

const int matrix2[4] = {
    0, 2,
    3, 1
};
const int matrix4[16] = {
    0,  8,  2,  10,
    12, 4,  14, 6,
    3,  11, 1,  9,
    15, 7,  13, 5
};
const int matrix8[64] = {
    0,  32, 8,  40, 2,  34, 10, 42,
    48, 16, 56, 24, 50, 18, 58, 26,
    12, 44, 4,  36, 14, 46, 6,  38,
    60, 28, 52, 20, 62, 30, 54, 22,
    3,  35, 11, 43, 1,  33, 9,  41,
    51, 19, 59, 27, 49, 17, 57, 25,
    15, 47, 7,  39, 13, 45, 5,  37,
    63, 31, 55, 23, 61, 29, 53, 21
};

int _getBayer(ivec2 cell) {
    int bayer_size = 1 << dither_pattern;
    ivec2 iv = ivec2(cell.x % bayer_size, cell.y % bayer_size);
    int index = iv.x + iv.y * bayer_size;

    switch (bayer_size) {
        case 2:
            return matrix2[index];
        case 4:
            return matrix4[index];
        default:
            return matrix8[index];
    }
}

int _getDitherValue(vec2 in_world_vertex, int in_quant_size) {
    int q_size = max(in_quant_size, 1);
    ivec2 cell = ivec2(floor(in_world_vertex / float(q_size)));
    return _getBayer(cell);
}

vec4 _ditherInternal(vec4 in_c, int in_dither_value) {
    vec3 c = in_c.rgb;
    float a = in_c.a;

    float bayer_size = float(1 << dither_pattern);
    float inv_bayer_squared = 1. / (bayer_size * bayer_size);
    float levels_f = max(float(levels) - 1., 1.);
    float inv_levels_f = 1. / levels_f;

    // normalize the dither value
    float dN = (float(in_dither_value) * inv_bayer_squared) - 0.5;
    // get the normalizing value for the division gap
    float r = inv_levels_f;
    float l = r * (inv_bayer_squared * 0.5);
    // add dither value to color
    c += r * dN + l;
    // convert normalized color to quantized range
    c = round(c * levels_f) * inv_levels_f;
    return vec4(c, a);
}

vec4 dither(vec4 in_color, vec2 in_world_vertex, int in_quant_size) {
    if (!dither_enabled) {
        return in_color;
    }

    int dither_value = _getDitherValue(in_world_vertex, in_quant_size);
    vec4 color = _ditherInternal(in_color, dither_value);

    return color;
}

// end dither.gdshaderinc

// adjustment.gdshaderinc

group_uniforms Adjustment;
/**Modifies the contrast of the image.*/
uniform float contrast : hint_range(0, 4) = 1.0;
/**Shifts the colors higher or lower.*/
uniform float brightness : hint_range (-1, 1) = 0;
/**
When Levels is 1 (black and white), or if Palette mode is 1, the colors are averaged.
This slider mixes between a luminance average, or a normal average.
0 = luminance average
1 = average
*/
uniform float average : hint_range(0.,1.) = 0;
group_uniforms;

const vec3 lum = vec3(0.2126, 0.7152, 0.0722);

float _getAverage(vec3 in_color) {
    float avg = (in_color.r + in_color.g + in_color.b) * 0.3333;
    float lum_avg = dot(in_color, lum);
    return mix(lum_avg, avg, average);
}

vec3 adjust(vec3 in_c, bool in_average) {
    vec3 c = in_c;

    if (in_average) {
        c = vec3(_getAverage(c));
    }

    return (c - 0.5 + brightness) * contrast + 0.5;
}

// end adjustment.gdshaderinc

// palette.gdshaderinc

group_uniforms Palette;
/**
0 = No palette: Simple color reduction
1 = Palette lookup based on luminance
*/
uniform int palette_mode : hint_range(0,1) = 0;

/**
A palette image or a GradientTexture1D for realtime editing.
Make sure the width of the GradientTexture1D matches the number of colors.
*/
uniform sampler2D palette : filter_nearest, repeat_disable;
group_uniforms;

vec4 addPalette(vec4 in_c, float in_levels) {
    if (palette_mode == 0) {
        return in_c;
    }

    vec3 c = in_c.rgb;
    float a = in_c.a;
    float levels_f = in_levels - 1.;
    int index;
    ivec2 palette_size = textureSize(palette, 0);
    int palette_total = palette_size.x * palette_size.y - 1;
    c *= levels_f;

    c.r = (c.r + c.g + c.b) * 0.3333;
    c.r = clamp(c.r / levels_f, 0.0, 1.0);
    index = int(round(c.r * float(palette_total)));

    // handle any height palette
    index = clamp(index, 0, palette_total);
    int col = index % palette_size.x;
    int row = index / palette_size.x ;
    vec2 uv = (vec2(ivec2(col, row)) + 0.5) / vec2(palette_size);
    return vec4(texture(palette, uv).rgb, in_c.a);
}

// end palette.gdshaderinc

void vertex() {
    float zoom = length(CANVAS_MATRIX[1].xyz);
    v_quant_size = getQuantizeSize(zoom);
    v_model_matrix = mat2(MODEL_MATRIX[0].xy, MODEL_MATRIX[1].xy);
    v_model_tr = MODEL_MATRIX[3].xy;
    v_vertex = VERTEX;

    if (texture_mode == 0) {
        mat4 alt_mat = inverse(MODEL_MATRIX);
        v_alt_matrix = mat2(alt_mat[0].xy, alt_mat[1].xy);
        v_alt_tr = alt_mat[3].xy;
        v_texture_data.xy = 1. / TEXTURE_PIXEL_SIZE;
    } else {
        mat4 world_to_clip = SCREEN_MATRIX * CANVAS_MATRIX;


        if (!snap_to_world) {
            mat4 inv_wtoc = inverse(SCREEN_MATRIX * CANVAS_MATRIX);
            v_alt_matrix = mat2(inv_wtoc[0].xy, inv_wtoc[1].xy);
            v_alt_tr = inv_wtoc[3].xy;
        } else {
            v_alt_matrix = mat2(world_to_clip[0].xy, world_to_clip[1].xy);
            v_alt_tr = world_to_clip[3].xy;
        }

        vec2 local_origin = v_model_matrix * vec2(0) + v_model_tr;
        vec2 clip = (world_to_clip * vec4(local_origin, 0,1)).xy;
        vec2 screen_origin_uv = clip * 0.5 + 0.5;
        vec2 quant_pixel_size = vec2(float(v_quant_size) * zoom);
        v_texture_data.xy = screen_origin_uv;
        v_texture_data.zw = quant_pixel_size;
    }
}

void fragment() {
    vec4 color;
    vec4 uvResult;

    if (texture_mode == 0) {
        uvResult = getQuantizeTextureUV(UV);
        color = texture(TEXTURE, uvResult.xy);
    } else {
        uvResult = getQuantizeScreenUV(SCREEN_UV, SCREEN_PIXEL_SIZE);
        color = texture(SCREEN_TEXTURE, uvResult.xy);
    }

    // Set alpha as color
    if (alpha_mode != 0) {
        color.rgb = vec3(1. - color.a);
    }

    color.rgb = adjust(color.rgb, palette_mode == 1 || levels == 1);
    color = dither(color, uvResult.zw, v_quant_size);
    color = addPalette(color, float(levels));

    // Set color as alpha
    if (alpha_mode != 0) {
        color = vec4(0, 0, 0, 1. - color.r);
    }

    // Show background in cutout
    if (alpha_mode == 2) {
        color = vec4(texture(SCREEN_TEXTURE, SCREEN_UV).rgb, color.a);
    }

    COLOR = color;
}