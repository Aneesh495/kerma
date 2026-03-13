#version 450 core

/**
 * Kerma Radiation Oncology Simulation Engine
 * 3D Direct Volume Raymarching with Isodose Shell Blending Fragment Shader
 *
 * Front-to-back emission-absorption raymarching:
 * - Samples anatomical CT density and 3D radiation dose grids
 * - Blinn-Phong shaded anatomical surfaces (skin and cortical bone)
 * - Volumetric semi-transparent 3D isodose cloud shells
 * - Early ray termination when accumulated alpha approaches 0.99
 */

layout(location = 0) in vec3 v_ray_origin_mm;
layout(location = 1) in vec3 v_ray_direction;

layout(location = 0) out vec4 out_frame_color;

layout(binding = 0) uniform sampler3D u_ct_volume_sampler;
layout(binding = 1) uniform sampler3D u_dose_volume_sampler;

layout(std140, binding = 1) uniform VolumeRenderConfig {
    vec3  box_min_mm;           // Patient bounding box min
    vec3  box_max_mm;           // Patient bounding box max
    vec3  light_direction;      // Directional light vector
    float step_size_mm;         // Raymarch integration step size (e.g. 1.5 mm)
    float prescription_dose_gy; // Prescription reference dose
    float ct_density_scale;     // Opacity scale for anatomy
    float dose_opacity_scale;   // Opacity scale for dose cloud
    int   max_ray_steps;        // Maximum step count (e.g. 256)
};

/**
 * Slab-method Ray-AABB intersection tester.
 */
vec2 intersectAABB(vec3 ray_orig, vec3 ray_dir, vec3 b_min, vec3 b_max) {
    vec3 inv_d = 1.0 / max(vec3(1.0e-5), abs(ray_dir)) * sign(ray_dir);
    vec3 t0 = (b_min - ray_orig) * inv_d;
    vec3 t1 = (b_max - ray_orig) * inv_d;
    vec3 t_min = min(t0, t1);
    vec3 t_max = max(t0, t1);
    float t_enter = max(max(t_min.x, t_min.y), t_min.z);
    float t_exit  = min(min(t_max.x, t_max.y), t_max.z);
    return vec2(max(0.0, t_enter), t_exit);
}

/**
 * Gradient estimation for surface normal lighting.
 */
vec3 computeCTGradient(vec3 uv, float delta) {
    float dx = texture(u_ct_volume_sampler, uv + vec3(delta, 0.0, 0.0)).r -
               texture(u_ct_volume_sampler, uv - vec3(delta, 0.0, 0.0)).r;
    float dy = texture(u_ct_volume_sampler, uv + vec3(0.0, delta, 0.0)).r -
               texture(u_ct_volume_sampler, uv - vec3(0.0, delta, 0.0)).r;
    float dz = texture(u_ct_volume_sampler, uv + vec3(0.0, 0.0, delta)).r -
               texture(u_ct_volume_sampler, uv - vec3(0.0, 0.0, delta)).r;
    vec3 grad = vec3(dx, dy, dz);
    return (length(grad) > 1.0e-5) ? normalize(-grad) : vec3(0.0, 1.0, 0.0);
}

void main() {
    vec3 ray_dir = normalize(v_ray_direction);
    vec2 t_bounds = intersectAABB(v_ray_origin_mm, ray_dir, box_min_mm, box_max_mm);

    if (t_bounds.x >= t_bounds.y || t_bounds.y <= 0.0) {
        out_frame_color = vec4(0.02, 0.02, 0.03, 1.0); // Ambient space
        return;
    }

    float t_current = t_bounds.x;
    float t_end     = t_bounds.y;

    vec3 box_span_mm = box_max_mm - box_min_mm;
    vec4 accum_color = vec4(0.0);

    vec3 light_dir_norm = normalize(light_direction);

    for (int step = 0; step < max_ray_steps; ++step) {
        if (t_current >= t_end || accum_color.a >= 0.98) {
            break;
        }

        vec3 current_pos_mm = v_ray_origin_mm + ray_dir * t_current;
        vec3 uv = (current_pos_mm - box_min_mm) / box_span_mm;

        // Sample anatomical density
        float ct_hu = texture(u_ct_volume_sampler, uv).r;
        float dose_gy = texture(u_dose_volume_sampler, uv).r;

        vec4 sample_color = vec4(0.0);

        // Render bone and skin surfaces
        if (ct_hu > -200.0) {
            vec3 normal = computeCTGradient(uv, 0.005);
            float diffuse = max(0.2, dot(normal, light_dir_norm));
            
            if (ct_hu > 300.0) { // Cortical bone
                sample_color = vec4(vec3(0.95, 0.90, 0.80) * diffuse, 0.12 * ct_density_scale);
            } else if (ct_hu > -100.0) { // Soft tissue / skin
                sample_color = vec4(vec3(0.85, 0.65, 0.55) * diffuse, 0.03 * ct_density_scale);
            }
        }

        // Overlay semi-transparent isodose shells
        float rel_dose = (prescription_dose_gy > 0.0) ? (dose_gy / prescription_dose_gy) : 0.0;
        if (rel_dose >= 0.30) {
            vec3 dose_rgb = vec3(0.0);
            if (rel_dose >= 0.95) dose_rgb = vec3(1.0, 0.1, 0.0); // 95% Red
            else if (rel_dose >= 0.80) dose_rgb = vec3(1.0, 0.8, 0.0); // 80% Yellow
            else if (rel_dose >= 0.50) dose_rgb = vec3(0.0, 0.9, 0.2); // 50% Green
            else dose_rgb = vec3(0.0, 0.4, 0.9); // 30% Blue

            float dose_alpha = 0.08 * dose_opacity_scale * smoothstep(0.30, 0.95, rel_dose);
            sample_color = mix(sample_color, vec4(dose_rgb, dose_alpha), 0.6);
        }

        // Front-to-back compositing
        if (sample_color.a > 0.0) {
            accum_color.rgb += (1.0 - accum_color.a) * sample_color.rgb * sample_color.a;
            accum_color.a   += (1.0 - accum_color.a) * sample_color.a;
        }

        t_current += step_size_mm;
    }

    // Blend over background
    vec3 background = vec4(0.02, 0.02, 0.03, 1.0).rgb;
    vec3 final_rgb = accum_color.rgb + (1.0 - accum_color.a) * background;

    out_frame_color = vec4(final_rgb, 1.0);
}
