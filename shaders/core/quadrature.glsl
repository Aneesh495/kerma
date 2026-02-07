/**
 * Kerma Radiation Oncology Simulation Engine
 * Spherical quadrature schemes, discrete ordinates angular directions,
 * and collapsed cone solid angle spatial discretization.
 */

#ifndef KERMA_QUADRATURE_GLSL
#define KERMA_QUADRATURE_GLSL

#include "constants.glsl"

#define CCCS_CONE_COUNT 128
#define S8_DIRECTION_COUNT 80

struct SphericalDirection {
    vec3  vector;       // Normalized 3D direction vector (Omega)
    float solid_angle;  // Solid angle weight (steradians, dOmega)
    float polar_theta;  // Polar angle in radians [0, pi]
    float azimuthal_phi;// Azimuthal angle in radians [0, 2pi]
};

/**
 * Computes Fibonacci spherical lattice point for index i out of N total directions.
 * Guarantees uniform spatial distribution across 4pi solid angle.
 */
SphericalDirection getFibonacciDirection(int index, int total_count) {
    SphericalDirection dir;
    float golden_ratio = 1.618033988749895;
    float i = float(index) + 0.5;
    
    // Z coordinate from 1 down to -1
    float z = 1.0 - (2.0 * i) / float(total_count);
    float radius = sqrt(max(0.0, 1.0 - z * z));
    
    // Golden angle rotation in radians
    float theta = TWO_PI * i / golden_ratio;
    
    dir.vector = vec3(radius * cos(theta), radius * sin(theta), z);
    dir.solid_angle = FOUR_PI / float(total_count);
    dir.polar_theta = acos(clamp(z, -1.0, 1.0));
    dir.azimuthal_phi = atan(dir.vector.y, dir.vector.x);
    if (dir.azimuthal_phi < 0.0) {
        dir.azimuthal_phi += TWO_PI;
    }
    
    return dir;
}

/**
 * Transforms an unperturbed spherical direction along a primary beam ray axis.
 * Performs coordinate frame reorientation so that the cone distribution aligns
 * with divergent radiation propagation vectors.
 */
vec3 orientConeDirection(vec3 local_cone_dir, vec3 primary_ray_dir) {
    vec3 ref_axis = vec3(0.0, 0.0, 1.0);
    float cos_angle = dot(ref_axis, primary_ray_dir);
    
    // Handle parallel and antiparallel edge cases
    if (cos_angle > 0.999999) {
        return local_cone_dir;
    }
    if (cos_angle < -0.999999) {
        return vec3(local_cone_dir.x, -local_cone_dir.y, -local_cone_dir.z);
    }
    
    vec3 rot_axis = normalize(cross(ref_axis, primary_ray_dir));
    float sin_angle = sqrt(max(0.0, 1.0 - cos_angle * cos_angle));
    
    // Rodrigues rotation formula: v_rot = v*cos + (k x v)*sin + k*(k . v)*(1 - cos)
    vec3 term1 = local_cone_dir * cos_angle;
    vec3 term2 = cross(rot_axis, local_cone_dir) * sin_angle;
    vec3 term3 = rot_axis * dot(rot_axis, local_cone_dir) * (1.0 - cos_angle);
    
    return normalize(term1 + term2 + term3);
}

/**
 * Discrete Ordinates S8 level-symmetric direction lookup.
 * Generates directional cosines for multigroup radiation transport.
 */
vec3 getDiscreteOrdinatesS8(int index) {
    // S8 quadrature directional cosine roots
    const float xi_1 = 0.21821789;
    const float xi_2 = 0.57735027;
    const float xi_3 = 0.78679579;
    
    // Octant selection based on index (0 to 79)
    int octant = index / 10;
    int local_idx = index % 10;
    
    vec3 signs = vec3(
        (octant & 1) != 0 ? -1.0 : 1.0,
        (octant & 2) != 0 ? -1.0 : 1.0,
        (octant & 4) != 0 ? -1.0 : 1.0
    );
    
    vec3 abs_dir;
    if (local_idx == 0)      abs_dir = vec3(xi_1, xi_1, xi_3);
    else if (local_idx == 1) abs_dir = vec3(xi_1, xi_2, xi_2);
    else if (local_idx == 2) abs_dir = vec3(xi_1, xi_3, xi_1);
    else if (local_idx == 3) abs_dir = vec3(xi_2, xi_1, xi_2);
    else if (local_idx == 4) abs_dir = vec3(xi_2, xi_2, xi_1);
    else if (local_idx == 5) abs_dir = vec3(xi_3, xi_1, xi_1);
    else if (local_idx == 6) abs_dir = vec3(xi_2, xi_3, xi_1);
    else if (local_idx == 7) abs_dir = vec3(xi_3, xi_2, xi_1);
    else if (local_idx == 8) abs_dir = vec3(xi_1, xi_2, xi_3);
    else                     abs_dir = vec3(xi_3, xi_1, xi_2);
    
    return normalize(abs_dir * signs);
}

#endif // KERMA_QUADRATURE_GLSL
