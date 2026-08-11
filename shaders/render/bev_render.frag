#version 450 core

/**
 * Kerma Radiation Oncology Simulation Engine
 * Beam's Eye View (BEV) DRR Raycaster & MLC Aperture Fragment Shader
 *
 * Implements:
 * - Divergent cone-beam ray integration through 3D CT attenuation volume (DRR synthesis)
 * - Projection of 60 Millenium-120 MLC leaf pairs and asymmetric backup jaws
 * - Target ROI volumetric silhouette projection in Beam's Eye View
 * - Calibrated isocenter millimeter reticle and CAX crosshairs overlay
 */

layout(location = 0) in vec2 v_tex_coord;
layout(location = 1) in vec2 v_iso_plane_mm;
layout(location = 0) out vec4 out_color;

// 3D CT linear attenuation volume
layout(binding = 0) uniform sampler3D u_ct_density_tex;

// 3D PTV target binary mask for BEV silhouette projection
layout(binding = 1) uniform sampler3D u_target_mask_tex;

// MLC 60-leaf pairs buffer (x = Bank A position mm, y = Bank B position mm, z = leaf width mm, w = y center mm)
layout(std430, binding = 2) readonly buffer MLCLeavesBuffer {
    vec4 b_mlc_leaves[60];
};

layout(std140, binding = 3) uniform BEVRenderConfig {
    vec3  source_pos_mm;       // Divergent X-ray focus position in world space
    vec3  isocenter_mm;        // Plan isocenter in world space
    vec3  beam_u_axis;         // Rightward leaf-travel axis (IEC X_c)
    vec3  beam_v_axis;         // Superior-inferior axis perpendicular to leaf travel (IEC Y_c)
    vec3  beam_w_axis;         // Unit vector from source toward isocenter
    vec3  vol_origin_mm;
    vec3  vol_extent_mm;
    vec4  jaw_positions_mm;    // (X1, X2, Y1, Y2) at isocenter
    float sad_mm;              // Source-to-Axis Distance (1000.0 mm)
    float drr_contrast_scale;
    int   num_ray_steps;       // e.g. 96 steps along cone ray
};

void main() {
    // Reconstruct 3D world position on isocenter plane
    vec3 iso_point = isocenter_mm + v_iso_plane_mm.x * beam_u_axis + v_iso_plane_mm.y * beam_v_axis;
    vec3 ray_dir = normalize(iso_point - source_pos_mm);

    float ray_start_mm = max(sad_mm - 300.0f, 50.0f);
    float ray_end_mm = sad_mm + 300.0f;
    float step_len = (ray_end_mm - ray_start_mm) / float(max(num_ray_steps, 16));

    float radiological_integral = 0.0f;
    float target_hit = 0.0f;

    for (int s = 0; s < num_ray_steps; ++s) {
        float t = ray_start_mm + (float(s) + 0.5f) * step_len;
        vec3 p_world = source_pos_mm + t * ray_dir;
        vec3 uvw = (p_world - vol_origin_mm) / vol_extent_mm;

        if (all(greaterThanEqual(uvw, vec3(0.0f))) && all(lessThanEqual(uvw, vec3(1.0f)))) {
            float rho_e = texture(u_ct_density_tex, uvw).r;
            radiological_integral += max(rho_e, 0.0f) * step_len;

            float mask = texture(u_target_mask_tex, uvw).r;
            target_hit = max(target_hit, mask);
        }
    }

    // Exponential transmission mapped to clinical DRR grayscale
    float drr_intensity = 1.0f - exp(-0.0045f * radiological_integral * drr_contrast_scale);
    vec3 color = vec3(clamp(drr_intensity, 0.0f, 1.0f));

    // Tint target silhouette projection in BEV (subtle warm crimson wash)
    if (target_hit > 0.5f) {
        color = mix(color, vec3(0.95f, 0.25f, 0.20f), 0.28f);
    }

    // Check collimator jaw occlusion
    float x_bev = v_iso_plane_mm.x;
    float y_bev = v_iso_plane_mm.y;
    bool inside_jaws = (x_bev >= jaw_positions_mm.x && x_bev <= jaw_positions_mm.y &&
                        y_bev >= jaw_positions_mm.z && y_bev <= jaw_positions_mm.w);

    // Check 60 MLC leaves
    bool shielded_by_mlc = false;
    for (int i = 0; i < 60; ++i) {
        vec4 leaf = b_mlc_leaves[i];
        float half_w = 0.5f * leaf.z;
        if (abs(y_bev - leaf.w) <= half_w) {
            if (x_bev < leaf.x || x_bev > leaf.y) {
                shielded_by_mlc = true;
            }
            break;
        }
    }

    // Darken collimated regions (jaws darker than MLC leaves)
    if (!inside_jaws) {
        color *= 0.22f;
    } else if (shielded_by_mlc) {
        color = mix(color * 0.45f, vec3(0.10f, 0.16f, 0.25f), 0.35f);
    }

    // Render calibrated CAX crosshairs and 50 mm graticule ticks
    float axis_dist = min(abs(x_bev), abs(y_bev));
    if (axis_dist < 0.45f) {
        float mod_tick = mod(max(abs(x_bev), abs(y_bev)), 10.0f);
        if (mod_tick < 1.2f) {
            color = mix(color, vec3(0.1f, 0.95f, 0.55f), 0.85f);
        } else {
            color = mix(color, vec3(0.1f, 0.85f, 0.45f), 0.40f);
        }
    }

    out_color = vec4(color, 1.0f);
}
