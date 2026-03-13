#version 450 core

/**
 * Kerma Radiation Oncology Simulation Engine
 * Multi-Planar Reconstruction (MPR) Cutting Plane Vertex Shader
 *
 * Positions screen-space quads aligned with anatomical cutting planes:
 * - Axial (Transverse, Z-plane)
 * - Coronal (Frontal, Y-plane)
 * - Sagittal (Median, X-plane)
 * - Oblique Beam's Eye View (BEV) plane
 */

layout(location = 0) in vec2 in_position;
layout(location = 1) in vec2 in_tex_coord;

layout(location = 0) out vec2 v_tex_coord;
layout(location = 1) out vec3 v_world_sample_pos_mm;

layout(std140, binding = 0) uniform MPRPlaneConfig {
    mat4 plane_transform_matrix; // Maps 2D quad coordinates [-1, 1] into 3D patient world mm
    vec3 plane_origin_mm;
    vec3 plane_u_axis_mm;
    vec3 plane_v_axis_mm;
};

void main() {
    v_tex_coord = in_tex_coord;
    
    // Map [-1, 1] quad coordinate to physical 3D plane position
    v_world_sample_pos_mm = plane_origin_mm + in_position.x * plane_u_axis_mm + in_position.y * plane_v_axis_mm;
    
    gl_Position = vec4(in_position, 0.0, 1.0);
}
