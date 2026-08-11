#version 450 core

/**
 * Kerma Radiation Oncology Simulation Engine
 * Beam's Eye View (BEV) Radiograph Vertex Shader
 *
 * Maps viewport coordinates to divergent Linac source-to-isocenter plane coordinates (mm).
 */

layout(location = 0) in vec2 in_position;
layout(location = 1) in vec2 in_tex_coord;

layout(location = 0) out vec2 v_tex_coord;
layout(location = 1) out vec2 v_iso_plane_mm;

layout(std140, binding = 0) uniform BEVVertexConfig {
    vec2 half_field_fov_mm; // Half width/height at isocenter plane (e.g. 200 x 200 mm)
};

void main() {
    v_tex_coord = in_tex_coord;
    v_iso_plane_mm = in_position * half_field_fov_mm;
    gl_Position = vec4(in_position, 0.0f, 1.0f);
}
