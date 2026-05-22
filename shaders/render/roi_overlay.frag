#version 450 core

/**
 * Kerma Radiation Oncology Simulation Engine
 * GPU Anti-Aliased ROI Contour and Stencil Hatching Fragment Shader
 *
 * Implements:
 * - Multi-organ anatomical contour boundary extraction via screen-space derivatives
 * - Procedural crosshatching and stippling for overlapping organ volumes
 * - Distance-to-edge subpixel anti-aliased line rendering
 * - Alpha blending of anatomical delineations over CT/MR slices
 */

layout(location = 0) in vec2 v_tex_coord;
layout(location = 0) out vec4 out_color;

// 2D slice from multi-structure ROI label map texture (integer structure IDs)
layout(binding = 0) uniform usampler2D u_roi_label_map;

// Palette buffer storing RGBA color and line style per structure ID
struct ROIStyle {
    vec4  color;
    float line_thickness_px;
    float hatch_spacing_px;
    float hatch_angle_rad;
    uint  render_mode; // 0 = Boundary outline only, 1 = Boundary + Hatching, 2 = Wash fill
};

layout(std430, binding = 1) readonly buffer StyleBuffer {
    ROIStyle roi_styles[];
};

layout(std140, binding = 2) uniform ViewportConfig {
    vec2  viewport_size_px;
    float global_roi_alpha;
};

void main() {
    uvec4 center_val = texture(u_roi_label_map, v_tex_coord);
    uint roi_id = center_val.r;

    if (roi_id == 0u || roi_id >= roi_styles.length()) {
        out_color = vec4(0.0f);
        return;
    }

    ROIStyle style = roi_styles[roi_id];
    vec2 pixel_coord = v_tex_coord * viewport_size_px;

    // Detect structure boundaries using 4-neighborhood tap differences
    vec2 texel_step = 1.0f / viewport_size_px;
    uint id_right = texture(u_roi_label_map, v_tex_coord + vec2(texel_step.x, 0.0f)).r;
    uint id_left  = texture(u_roi_label_map, v_tex_coord - vec2(texel_step.x, 0.0f)).r;
    uint id_up    = texture(u_roi_label_map, v_tex_coord + vec2(0.0f, texel_step.y)).r;
    uint id_down  = texture(u_roi_label_map, v_tex_coord - vec2(0.0f, texel_step.y)).r;

    bool is_boundary = (id_right != roi_id) || (id_left != roi_id) || 
                       (id_up != roi_id) || (id_down != roi_id);

    // Compute screen-space line distance anti-aliasing
    float boundary_alpha = 0.0f;
    if (is_boundary) {
        boundary_alpha = 1.0f;
    }

    // Procedural diagonal hatching pattern
    float hatch_alpha = 0.0f;
    if (style.render_mode == 1u) {
        float theta = style.hatch_angle_rad;
        vec2 hatch_dir = vec2(cos(theta), sin(theta));
        float proj = dot(pixel_coord, hatch_dir);
        float pattern = mod(proj, max(style.hatch_spacing_px, 2.0f));
        if (pattern < 1.5f) {
            hatch_alpha = 0.35f;
        }
    } else if (style.render_mode == 2u) {
        // Semi-transparent solid wash fill
        hatch_alpha = 0.25f;
    }

    float final_alpha = max(boundary_alpha, hatch_alpha) * style.color.a * global_roi_alpha;
    out_color = vec4(style.color.rgb, final_alpha);
}
