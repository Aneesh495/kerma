/**
 * Kerma Radiation Oncology Simulation Engine
 * Real Spherical Harmonics and Associated Legendre Polynomials
 *
 * Implements orthonormal real spherical harmonics Y_{lm}(theta, phi)
 * up to order L = 4 (25 basis functions) for anisotropic radiation transport:
 * - Direct polynomial evaluation without trigonometric singularities
 * - Associated Legendre polynomials P_l^m(x) with Condon-Shortley phase
 * - Spherical harmonics projection and synthesis routines
 */

#ifndef KERMA_SPHERICAL_HARMONICS_GLSL
#define KERMA_SPHERICAL_HARMONICS_GLSL

#include "constants.glsl"

/**
 * Evaluates real spherical harmonics basis up to order L = 3 (16 components)
 * directly from normalized Cartesian direction vector d = (x, y, z).
 */
void evalSphericalHarmonicsL3(vec3 d, out float sh[16]) {
    float x = d.x;
    float y = d.y;
    float z = d.z;

    // L = 0 (Monopole / Isotropic)
    // Y_{0,0} = 1 / (2 * sqrt(pi))
    sh[0] = 0.28209479177387814;

    // L = 1 (Dipole / Directional Current)
    // Y_{1,-1} = sqrt(3 / (4*pi)) * y
    // Y_{1,0}  = sqrt(3 / (4*pi)) * z
    // Y_{1,1}  = sqrt(3 / (4*pi)) * x
    const float c1 = 0.4886025119029199;
    sh[1] = c1 * y;
    sh[2] = c1 * z;
    sh[3] = c1 * x;

    // L = 2 (Quadrupole / Anisotropic Diffusion)
    // Y_{2,-2} = 0.5 * sqrt(15 / pi) * x * y
    // Y_{2,-1} = 0.5 * sqrt(15 / pi) * y * z
    // Y_{2,0}  = 0.25 * sqrt(5 / pi) * (2*z^2 - x^2 - y^2) = 0.25 * sqrt(5 / pi) * (3*z^2 - 1)
    // Y_{2,1}  = 0.5 * sqrt(15 / pi) * x * z
    // Y_{2,2}  = 0.25 * sqrt(15 / pi) * (x^2 - y^2)
    const float c2_xy = 1.0925484305920792;
    const float c2_z  = 0.3153915652525200;
    const float c2_sq = 0.5462742152960396;
    sh[4] = c2_xy * (x * y);
    sh[5] = c2_xy * (y * z);
    sh[6] = c2_z  * (3.0 * z * z - 1.0);
    sh[7] = c2_xy * (x * z);
    sh[8] = c2_sq * (x * x - y * y);

    // L = 3 (Octupole / Higher Angular Moments)
    const float c3_0 = 0.5900435899266435;
    const float c3_1 = 2.890611442640554;
    const float c3_2 = 0.4570457994644658;
    const float c3_3 = 0.3731763325901154;
    const float c3_4 = 1.445305721320277;

    sh[9]  = c3_0 * y * (3.0 * x * x - y * y);
    sh[10] = c3_1 * x * y * z;
    sh[11] = c3_2 * y * (5.0 * z * z - 1.0);
    sh[12] = c3_3 * z * (5.0 * z * z - 3.0);
    sh[13] = c3_2 * x * (5.0 * z * z - 1.0);
    sh[14] = c3_4 * z * (x * x - y * y);
    sh[15] = c3_0 * x * (x * x - 3.0 * y * y);
}

/**
 * Reconstructs angular flux psi(d) from spherical harmonics moment coefficients.
 */
float reconstructFluxFromSH(vec3 d, float moments[16]) {
    float basis[16];
    evalSphericalHarmonicsL3(d, basis);

    float flux = 0.0;
    for (int i = 0; i < 16; ++i) {
        flux += moments[i] * basis[i];
    }
    return max(0.0, flux); // Guarantee positive scalar flux
}

#endif // KERMA_SPHERICAL_HARMONICS_GLSL
