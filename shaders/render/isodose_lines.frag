#version 450 core

/**
 * Kerma Radiation Oncology Simulation Engine
 * Screen-Space Anti-Aliased Isodose Contour Line Drawing Fragment Shader
 *
 * Renders sub-pixel anti-aliased isodose contour lines across cutting planes:
 *   distance = | D(x, y) - D_iso | / | nabla D |
 *
 * Distinct clinical color coding:
 * - 105% Hot spot line: Magenta
 * - 100% Prescription line: Red
 * - 95% Target coverage line: Orange
 * - 80% Shoulder line: Yellow
 * - 70% Intermediate line: Green
 * - 50% Half-dose line: Cyan
 * - 30% Normal tissue sparing line: Blue
 */

layout(location = 0) in vec2 v_tex_coord;
layout(location = 1) in vec3 v_world_sample_pos_mm;

layout(location = 0) out vec4 out_isodose_overlay;

layout(binding = 0) uniform sampler3D u_dose_volume_sampler;

layout(std140, binding = 1) uniform IsodoseLineConfig {
    vec3  grid_origin_mm;
    vec3  voxel_spacing_mm;
    ivec3 volume_dimensions;
    float prescription_dose_gy;
    float line_width_pixels;    // Desired line width in screen pixels (e.g. 1.5)
};

const int NUM_ISODOSE_LEVELS = 7;
const float ISO_LEVELS[7] = float[](1.05, 1.00, 0.95, 0.80, 0.70, 0.50, 0.30);
const vec3 ISO_COLORS[7] = vec3[](
    vec3(1.0, 0.1, 0.9), // 105% Magenta
    vec3(1.0, 0.0, 0.0), // 100% Red
    vec3(1.0, 0.5, 0.0), // 95%  Orange
    vec3(0.9, 0.9, 0.0), // 80%  Yellow
    vec3(0.0, 0.8, 0.1), // 70%  Green
    vec3(0.0, 0.8, 0.9), // 50%  Cyan
    vec3(0.1, 0.2, 0.8)  // 30%  Blue
);

void main() {
    vec3 grid_span_mm = vec3(volume_dimensions) * voxel_spacing_mm;
    vec3 local_pos_mm = v_world_sample_pos_mm - grid_origin_mm;
    vec3 uv = local_pos_mm / grid_span_mm;

    if (any(lessThan(uv, vec3(0.0))) || any(greaterThan(uv, vec3(1.0)))) {
        discard;
    }

    float dose_gy = texture(u_dose_volume_sampler, uv).r;
    float rel_dose = (prescription_dose_gy > 0.0) ? (dose_gy / prescription_dose_gy) : 0.0;

    // Screen-space partial derivatives of relative dose: nabla D = (dD/dx, dD/dy)
    float d_dx = dFdx(rel_dose);
    float d_dy = dFdy(rel_dose);
    float grad_len = max(1.0e-5, length(vec2(d_dx, d_dy)));

    vec4 line_color_accum = vec4(0.0);

    for (int i = 0; i < NUM_ISODOSE_LEVELS; ++i) {
        float iso_val = ISO_LEVELS[i];
        // Distance in screen pixels to contour surface: dist_pixels = |D - D_iso| / |nabla D|
        float dist_pixels = abs(rel_dose - iso_val) / grad_len;

        // Anti-aliased line profile using smoothstep
        float half_width = 0.5 * line_width_pixels;
        float alpha = 1.0 - smoothstep(half_width - 0.75, half_width + 0.75, dist_pixels);

        if (alpha > 0.0) {
            line_color_accum = vec4(ISO_COLORS[i], max(line_color_accum.a, alpha));
        }
    }

    if (line_color_accum.a <= 0.01) {
        discard;
    }

    out_isodose_overlay = line_color_accum;
}
