/**
 * Kerma Radiation Oncology Simulation Engine
 * Parallel pseudorandom number generators, Sobol quasi-random routines,
 * and statistical distribution samplers for Monte Carlo phase-space simulation.
 */

#ifndef KERMA_RNG_GLSL
#define KERMA_RNG_GLSL

#include "constants.glsl"

struct PCGState {
    uint state;
    uint inc;
};

/**
 * Initializes PCG32 random state from thread spatial coordinates and simulation seed.
 */
PCGState initPCG32(uvec3 thread_id, uint base_seed) {
    PCGState s;
    // Hash thread ID components into state and sequence selector
    uint h = base_seed ^ (thread_id.x * 1973u + thread_id.y * 9277u + thread_id.z * 26699u);
    s.state = 0u;
    s.inc = (h << 1u) | 1u;
    // Step forward
    s.state = s.state * 747796405u + s.inc;
    s.state += 2891336453u;
    s.state = s.state * 747796405u + s.inc;
    return s;
}

/**
 * Advances PCG32 state and returns a uniformly distributed 32-bit unsigned integer.
 */
uint nextPCG32(inout PCGState s) {
    uint oldstate = s.state;
    s.state = oldstate * 747796405u + s.inc;
    uint xorshifted = ((oldstate >> ((oldstate >> 28u) + 4u)) ^ oldstate) * 277803737u;
    return (xorshifted >> 22u) ^ xorshifted;
}

/**
 * Generates a canonical uniform floating point number in [0.0, 1.0).
 */
float randUniform(inout PCGState s) {
    return float(nextPCG32(s)) * (1.0 / 4294967296.0);
}

/**
 * Generates a pair of standard normal (Gaussian) random variables via Box-Muller transform.
 */
vec2 randGaussianPair(inout PCGState s) {
    float u1 = max(randUniform(s), EPSILON_FLOAT);
    float u2 = randUniform(s);
    float radius = sqrt(-2.0 * log(u1));
    float theta  = TWO_PI * u2;
    return vec2(radius * cos(theta), radius * sin(theta));
}

/**
 * Generates an isotropic unit direction on the unit sphere surface.
 */
vec3 randSphericalDirection(inout PCGState s) {
    float z = 1.0 - 2.0 * randUniform(s);
    float r = sqrt(max(0.0, 1.0 - z * z));
    float phi = TWO_PI * randUniform(s);
    return vec3(r * cos(phi), r * sin(phi), z);
}

/**
 * Generates a cosine-weighted direction in the upper hemisphere defined by surface normal N.
 */
vec3 randCosineHemisphere(inout PCGState s, vec3 N) {
    float r1 = randUniform(s);
    float r2 = randUniform(s);
    float phi = TWO_PI * r1;
    float sin_theta = sqrt(r2);
    float cos_theta = sqrt(max(0.0, 1.0 - r2));
    
    vec3 local_dir = vec3(sin_theta * cos(phi), sin_theta * sin(phi), cos_theta);
    
    // Construct orthonormal basis around N
    vec3 up = abs(N.z) < 0.999 ? vec3(0.0, 0.0, 1.0) : vec3(1.0, 0.0, 0.0);
    vec3 tangent = normalize(cross(up, N));
    vec3 bitangent = cross(N, tangent);
    
    return normalize(tangent * local_dir.x + bitangent * local_dir.y + N * local_dir.z);
}

#endif // KERMA_RNG_GLSL
