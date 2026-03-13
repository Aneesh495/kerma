#version 450 core

/**
 * Kerma Radiation Oncology Simulation Engine
 * 3D Direct Volume Rendering (DVR) Raymarching Vertex Shader
 *
 * Emits screen-space camera frustum rays into 3D patient volume.
 */

layout(location = 0) in vec3 in_position;

layout(location = 0) out vec3 v_ray_origin_mm;
layout(location = 1) out vec3 v_ray_direction;

layout(std140, binding = 0) uniform CameraMatrices {
    mat4 view_matrix;
    mat4 proj_matrix;
    mat4 inv_view_proj;
    vec3 camera_pos_world_mm;
};

void main() {
    // Standard normalized device coordinates [-1, 1]
    gl_Position = vec4(in_position.xy, 0.0, 1.0);

    // Unproject near and far plane coordinates to determine camera ray in patient space
    vec4 near_world = inv_view_proj * vec4(in_position.xy, -1.0, 1.0);
    near_world /= near_world.w;

    vec4 far_world  = inv_view_proj * vec4(in_position.xy,  1.0, 1.0);
    far_world /= far_world.w;

    v_ray_origin_mm = near_world.xyz;
    v_ray_direction = normalize(far_world.xyz - near_world.xyz);
}
