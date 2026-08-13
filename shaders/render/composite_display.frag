#version 450 core

/**
 * Kerma Radiation Oncology Simulation Engine
 * Multi-Viewport 2x2 Clinical Workstation Composite Fragment Shader
 *
 * Implements:
 * - Quadrant composition for Axial, Sagittal, Coronal MPR planes and 3D/BEV view
 * - Synchronized anatomical crosshair cursor tracking across orthogonal views
 * - Dose colorbar legend rendering with prescribed normalization ticks
 * - Sub-pixel viewport borders and active panel highlight frame
 */

layout(location = 0) in vec2 v_tex_coord;
layout(location = 0) out vec4 out_color;

layout(binding = 0) uniform sampler2D u_axial_view;
layout(binding = 1) uniform sampler2D u_sagittal_view;
layout(binding = 2) uniform sampler2D u_coronal_view;
layout(binding = 3) uniform sampler2D u_3d_bev_view;

layout(std140, binding = 4) uniform WorkstationConfig {
    vec2  window_size_px;
    vec3  crosshair_uvw;       // Synchronized 3D cursor in [0, 1]^3
    uint  active_quadrant;     // 0=TL(Axial), 1=TR(Sagittal), 2=BL(Coronal), 3=BR(3D/BEV)
    float colorbar_width_uv;   // e.g. 0.025
};

// Jet-inspired smooth clinical dose wash colormap
vec3 dose_colorbar_lut(float t) {
    float x = clamp(t, 0.0f, 1.0f);
    vec3 c0 = vec3(0.05f, 0.15f, 0.55f); // Deep blue (low dose)
    vec3 c1 = vec3(0.10f, 0.75f, 0.85f); // Cyan (~30%)
    vec3 c2 = vec3(0.30f, 0.90f, 0.30f); // Green (~50%)
    vec3 c3 = vec3(0.95f, 0.85f, 0.10f); // Yellow (~80%)
    vec3 c4 = vec3(0.95f, 0.15f, 0.10f); // Crimson (100%+)

    if (x < 0.25f) return mix(c0, c1, x * 4.0f);
    if (x < 0.50f) return mix(c1, c2, (x - 0.25f) * 4.0f);
    if (x < 0.75f) return mix(c2, c3, (x - 0.50f) * 4.0f);
    return mix(c3, c4, (x - 0.75f) * 4.0f);
}

void main() {
    vec2 uv = v_tex_coord;
    vec2 pixel = uv * window_size_px;

    // Colorbar legend strip on far right edge
    if (uv.x > (1.0f - colorbar_width_uv)) {
        float bar_y = clamp((uv.y - 0.10f) / 0.80f, 0.0f, 1.0f);
        if (uv.y >= 0.10f && uv.y <= 0.90f) {
            vec3 ramp = dose_colorbar_lut(bar_y);
            // Major tick marks at every 10% interval
            float tick = mod(bar_y, 0.10f);
            if (tick < 0.005f) {
                ramp = vec3(1.0f);
            }
            out_color = vec4(ramp, 1.0f);
        } else {
            out_color = vec4(0.08f, 0.09f, 0.11f, 1.0f);
        }
        return;
    }

    // Scale remaining horizontal space [0, 1 - colorbar] into [0, 1]
    vec2 grid_uv = vec2(uv.x / max(1.0f - colorbar_width_uv, 0.1f), uv.y);

    // Quadrant selection
    bool is_right = (grid_uv.x >= 0.5f);
    bool is_top   = (grid_uv.y >= 0.5f);
    vec2 local_uv = fract(grid_uv * 2.0f);

    uint quad_id = (is_top ? 0u : 2u) + (is_right ? 1u : 0u);

    vec4 view_color = vec4(0.0f);
    vec2 crosshair_2d = vec2(-1.0f);

    if (quad_id == 0u) {
        view_color = texture(u_axial_view, local_uv);
        crosshair_2d = crosshair_uvw.xy;
    } else if (quad_id == 1u) {
        view_color = texture(u_sagittal_view, local_uv);
        crosshair_2d = crosshair_uvw.yz;
    } else if (quad_id == 2u) {
        view_color = texture(u_coronal_view, local_uv);
        crosshair_2d = crosshair_uvw.xz;
    } else {
        view_color = texture(u_3d_bev_view, local_uv);
    }

    vec3 rgb = view_color.rgb;

    // Render synchronized crosshairs in MPR panes (with gap at intersection)
    if (quad_id < 3u) {
        vec2 quad_px = local_uv * (0.5f * window_size_px);
        vec2 cross_px = crosshair_2d * (0.5f * window_size_px);
        float dx = abs(quad_px.x - cross_px.x);
        float dy = abs(quad_px.y - cross_px.y);
        float dist_center = length(quad_px - cross_px);

        if ((dx < 0.8f || dy < 0.8f) && dist_center > 5.0f) {
            vec3 line_col = (quad_id == 0u) ? vec3(0.2f, 0.9f, 0.4f) :
                            (quad_id == 1u) ? vec3(0.95f, 0.65f, 0.1f) :
                                              vec3(0.25f, 0.75f, 1.0f);
            rgb = mix(rgb, line_col, 0.65f);
        }
    }

    // Viewport borders and active quadrant highlight
    vec2 border_dist = min(local_uv, 1.0f - local_uv) * (0.5f * window_size_px);
    float min_border = min(border_dist.x, border_dist.y);
    if (min_border < 1.5f) {
        if (quad_id == active_quadrant) {
            rgb = vec3(0.20f, 0.80f, 0.95f); // Active cyan highlight
        } else {
            rgb = vec3(0.22f, 0.24f, 0.28f); // Subtle divider gray
        }
    }

    out_color = vec4(rgb, 1.0f);
}
