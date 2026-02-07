/**
 * Kerma Radiation Oncology Simulation Engine
 * Core geometric data structures, Ray-AABB bounding box solvers,
 * and IEC 61217 coordinate transformation routines.
 */

#ifndef KERMA_TYPES_GLSL
#define KERMA_TYPES_GLSL

#include "constants.glsl"

// IEC 61217 Linac Treatment Unit Configuration
struct LinacBeamSetup {
    vec3  isocenter_world_mm;   // World/Patient coordinates of isocenter
    float gantry_angle_rad;     // IEC gantry angle rotation (theta_g)
    float collimator_angle_rad; // IEC collimator rotation (theta_c)
    float couch_angle_rad;      // IEC treatment couch yaw (theta_t)
    float sad_mm;               // Source-to-Axis Distance (typically 1000 mm)
    vec4  jaw_aperture_mm;      // (x_min, x_max, y_min, y_max) at isocenter plane
    vec2  source_focal_spot_mm; // Gaussian focal spot FWHM (sigma_x, sigma_y)
    float monitor_units;        // Prescription monitor units (MU)
    float nominal_energy_mv;    // Nominal beam energy (e.g. 6.0, 10.0, 15.0 MV)
};

// 3D Patient CT Matrix and Spatial Metrology
struct PatientVolumeMetadata {
    vec3  grid_origin_mm;       // Physical position of voxel (0,0,0) in LPS
    vec3  voxel_spacing_mm;     // Spatial pitch (dx, dy, dz) in mm
    ivec3 matrix_dimensions;    // Number of columns, rows, slices (Nx, Ny, Nz)
    vec3  bounding_box_min_mm;  // Spatial AABB lower boundary
    vec3  bounding_box_max_mm;  // Spatial AABB upper boundary
};

// Geometric Ray Definition
struct DosimetryRay {
    vec3  origin_mm;            // Ray launch position
    vec3  direction;            // Normalized unit propagation vector
    float energy_mev;           // Monochromatic or effective spectral energy
    float radiant_weight;       // Relative intensity weight
    float t_min;                // Minimum parametric distance
    float t_max;                // Maximum parametric distance
};

// Ray-Volume Intersection Result
struct RayVolumeIntersection {
    bool  hit;                  // True if ray pierces volume bounding box
    float t_near_mm;            // Entry distance from ray origin
    float t_far_mm;             // Exit distance from ray origin
    vec3  entry_point_mm;       // Physical coordinate of entry surface
    vec3  exit_point_mm;        // Physical coordinate of exit surface
};

/**
 * Computes the physical position of the photon source in IEC patient coordinates.
 * Rotates the source about the isocenter according to gantry and couch angles.
 */
vec3 computeSourcePosition(LinacBeamSetup beam) {
    // In canonical IEC 61217 Gantry frame (before rotation), source is at (0, 0, -SAD)
    // with beam aimed along +Z towards isocenter at (0, 0, 0).
    // Gantry rotation rotates about the Y axis.
    float cos_g = cos(beam.gantry_angle_rad);
    float sin_g = sin(beam.gantry_angle_rad);
    
    // Position in room frame prior to couch rotation
    vec3 pos_room = vec3(
        -beam.sad_mm * sin_g,
        0.0,
        -beam.sad_mm * cos_g
    );
    
    // Couch rotation about room vertical axis (IEC Z or patient superior/inferior)
    float cos_t = cos(beam.couch_angle_rad);
    float sin_t = sin(beam.couch_angle_rad);
    
    vec3 pos_couch = vec3(
        pos_room.x * cos_t - pos_room.y * sin_t,
        pos_room.x * sin_t + pos_room.y * cos_t,
        pos_room.z
    );
    
    return beam.isocenter_world_mm + pos_couch;
}

/**
 * Transforms a point from patient world space (mm) into normalized [0, 1] texture coordinates.
 */
vec3 worldToTextureUV(vec3 world_pos_mm, PatientVolumeMetadata meta) {
    vec3 local_pos = world_pos_mm - meta.grid_origin_mm;
    vec3 grid_span = vec3(meta.matrix_dimensions) * meta.voxel_spacing_mm;
    return clamp(local_pos / grid_span, vec3(0.0), vec3(1.0));
}

/**
 * Transforms normalized texture coordinates [0, 1] into physical patient coordinates (mm).
 */
vec3 textureUVToWorld(vec3 uv, PatientVolumeMetadata meta) {
    vec3 grid_span = vec3(meta.matrix_dimensions) * meta.voxel_spacing_mm;
    return meta.grid_origin_mm + uv * grid_span;
}

/**
 * Robust Slab-method Ray-AABB intersection tester.
 * Calculates intersection intervals with patient volume boundary.
 */
RayVolumeIntersection intersectVolumeAABB(
    DosimetryRay ray,
    vec3 box_min,
    vec3 box_max
) {
    RayVolumeIntersection result;
    result.hit = false;
    result.t_near_mm = -LARGE_FLOAT;
    result.t_far_mm = LARGE_FLOAT;

    vec3 inv_dir = vec3(
        abs(ray.direction.x) > EPSILON_FLOAT ? 1.0 / ray.direction.x : 1.0 / (sign(ray.direction.x) * EPSILON_FLOAT),
        abs(ray.direction.y) > EPSILON_FLOAT ? 1.0 / ray.direction.y : 1.0 / (sign(ray.direction.y) * EPSILON_FLOAT),
        abs(ray.direction.z) > EPSILON_FLOAT ? 1.0 / ray.direction.z : 1.0 / (sign(ray.direction.z) * EPSILON_FLOAT)
    );

    vec3 t0 = (box_min - ray.origin_mm) * inv_dir;
    vec3 t1 = (box_max - ray.origin_mm) * inv_dir;

    vec3 t_smaller = min(t0, t1);
    vec3 t_larger  = max(t0, t1);

    float t_enter = max(max(t_smaller.x, t_smaller.y), t_smaller.z);
    float t_exit  = min(min(t_larger.x, t_larger.y), t_larger.z);

    if (t_enter <= t_exit && t_exit > 0.0) {
        result.hit = true;
        result.t_near_mm = max(t_enter, 0.0);
        result.t_far_mm = t_exit;
        result.entry_point_mm = ray.origin_mm + ray.direction * result.t_near_mm;
        result.exit_point_mm  = ray.origin_mm + ray.direction * result.t_far_mm;
    }

    return result;
}

#endif // KERMA_TYPES_GLSL
