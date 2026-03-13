#version 450 core

/**
 * Kerma Radiation Oncology Simulation Engine
 * Multi-Planar Reconstruction (MPR) Anatomical CT and Dose Colorwash Fragment Shader
 *
 * Blends grayscale anatomical CT slices with semi-transparent isodose colorwash:
 * - DICOM Window / Level contrast transfer function
 * - Clinical Rainbow / Jet / Turbo dose colormaps
 * - Alpha transparency blending with low-dose threshold suppression
 */

layout(location = 0) in vec2 v_tex_coord;
layout(location = 1) in vec3 v_world_sample_pos_mm;

layout(location = 0) out vec4 out_fragment_color;

layout(binding = 0) uniform sampler3D u_ct_volume_sampler;
layout(binding = 1) uniform sampler3D u_dose_volume_sampler;

layout(std140, binding = 1) uniform MPRRenderParams {
    vec3  grid_origin_mm;
    vec3  voxel_spacing_mm;
    ivec3 volume_dimensions;
    float window_width_hu;       // DICOM Window Width (e.g. 400 HU for soft tissue)
    float window_level_hu;       // DICOM Window Level (e.g. 40 HU for soft tissue)
    float prescription_dose_gy;  // 100% reference dose
    float dose_alpha_opacity;    // Transparency alpha [0.0, 1.0]
    float low_dose_cutoff_pct;   // Low dose cutoff (e.g. 0.10 for 10%)
};

/**
 * Converts relative dose in [0.0, 1.15] into clinical rainbow RGB colorwash.
 */
vec3 evaluateDoseColormap(float rel_dose) {
    if (rel_dose < 0.10) return vec3(0.0);
    // 10% to 30%: Dark blue to light blue
    if (rel_dose < 0.30) {
        float t = (rel_dose - 0.10) / 0.20;
        return mix(vec3(0.0, 0.0, 0.5), vec3(0.0, 0.4, 0.9), t);
    }
    // 30% to 50%: Blue to cyan / green
    if (rel_dose < 0.50) {
        float t = (rel_dose - 0.30) / 0.20;
        return mix(vec3(0.0, 0.4, 0.9), vec3(0.0, 0.8, 0.8), t);
    }
    // 50% to 70%: Cyan to pure green
    if (rel_dose < 0.70) {
        float t = (rel_dose - 0.50) / 0.20;
        return mix(vec3(0.0, 0.8, 0.8), vec3(0.0, 0.9, 0.2), t);
    }
    // 70% to 90%: Green to yellow
    if (rel_dose < 0.90) {
        float t = (rel_dose - 0.70) / 0.20;
        return mix(vec3(0.0, 0.9, 0.2), vec3(0.95, 0.95, 0.0), t);
    }
    // 90% to 100%: Yellow to pure red (prescription)
    if (rel_dose <= 1.00) {
        float t = (rel_dose - 0.90) / 0.10;
        return mix(vec3(0.95, 0.95, 0.0), vec3(1.0, 0.0, 0.0), t);
    }
    // > 100%: Red to magenta / white (hot spots)
    float t = clamp((rel_dose - 1.00) / 0.15, 0.0, 1.0);
    return mix(vec3(1.0, 0.0, 0.0), vec3(1.0, 0.2, 0.9), t);
}

void main() {
    vec3 grid_span_mm = vec3(volume_dimensions) * voxel_spacing_mm;
    vec3 local_pos_mm = v_world_sample_pos_mm - grid_origin_mm;
    vec3 uv = local_pos_mm / grid_span_mm;

    // Check bounds
    if (any(lessThan(uv, vec3(0.0))) || any(greaterThan(uv, vec3(1.0)))) {
        out_fragment_color = vec4(0.05, 0.05, 0.05, 1.0); // Ambient background
        return;
    }

    // Sample CT density / HU
    float hu_val = texture(u_ct_volume_sampler, uv).r;

    // DICOM Window / Level mapping: [Level - Width/2, Level + Width/2] -> [0, 1]
    float hu_min = window_level_hu - 0.5 * window_width_hu;
    float ct_gray = clamp((hu_val - hu_min) / max(1.0, window_width_hu), 0.0, 1.0);
    vec3 ct_color = vec3(ct_gray);

    // Sample physical absorbed dose
    float dose_gy = texture(u_dose_volume_sampler, uv).r;
    float rel_dose = (prescription_dose_gy > 0.0) ? (dose_gy / prescription_dose_gy) : 0.0;

    if (rel_dose >= low_dose_cutoff_pct) {
        vec3 dose_rgb = evaluateDoseColormap(rel_dose);
        float alpha = clamp(dose_alpha_opacity * smoothstep(low_dose_cutoff_pct, low_dose_cutoff_pct + 0.05, rel_dose), 0.0, 1.0);
        vec3 composite = mix(ct_color, dose_rgb, alpha);
        out_fragment_color = vec4(composite, 1.0);
    } else {
        out_fragment_color = vec4(ct_color, 1.0);
    }
}
