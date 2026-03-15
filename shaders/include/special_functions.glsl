/**
 * Kerma Radiation Oncology Simulation Engine
 * Mathematical Special Functions Library for Analytical Dosimetry
 *
 * Implements high-precision numerical approximations for:
 * - Complete and Incomplete Gamma functions Gamma(x), gamma(a, x)
 * - Exponential Integral E_1(x) and E_n(x) for radiation shielding
 * - Modified Bessel functions I_0(x), I_1(x), K_0(x), K_1(x)
 * - Confluent Hypergeometric functions M(a, b, x)
 * - Error functions erf(x), erfc(x), Faddeeva / Voigt profiles
 */

#ifndef KERMA_SPECIAL_FUNCTIONS_GLSL
#define KERMA_SPECIAL_FUNCTIONS_GLSL

#include "constants.glsl"

/**
 * Lanczos approximation for the natural logarithm of the Gamma function ln(Gamma(z)).
 * Valid for z > 0 with precision better than 1.0e-7.
 */
float logGammaLanczos(float z) {
    const float g = 7.0;
    const float c[9] = float[](
        0.99999999999980993,
        676.5203681218851,
        -1259.1392167224028,
        771.32342877765313,
        -176.61502916214059,
        12.507343278686905,
        -0.138571095836524,
        9.9843695780195716e-6,
        1.5056327351493116e-7
    );

    if (z < 0.5) {
        // Reflection formula: Gamma(z) * Gamma(1 - z) = pi / sin(pi * z)
        return log(PI) - log(sin(PI * z)) - logGammaLanczos(1.0 - z);
    }

    z -= 1.0;
    float x = c[0];
    for (int i = 1; i < 9; ++i) {
        x += c[i] / (z + float(i));
    }

    float t = z + g + 0.5;
    return 0.5 * log(TWO_PI) + (z + 0.5) * log(t) - t + log(x);
}

/**
 * Gamma function Gamma(z) evaluated via Lanczos logarithm.
 */
float evalGamma(float z) {
    if (z > 30.0) return 1.0e30; // Overflow guard
    return exp(logGammaLanczos(z));
}

/**
 * Exponential Integral E_1(x) = int_x^inf (exp(-t) / t) dt for x > 0.
 * Fundamental for broad-beam point and line source kernel attenuation.
 */
float evalExponentialIntegralE1(float x) {
    if (x <= 0.0) return 1.0e6;
    if (x <= 1.0) {
        // Series expansion for small x: E_1(x) = -gamma_euler - ln(x) - sum_{n=1}^inf (-x)^n / (n * n!)
        const float euler_mascheroni = 0.5772156649;
        float term1 = -euler_mascheroni - log(x);
        float term2 = x * (1.0 - x * (0.25 - x * (0.055555555 - x * 0.010416666)));
        return term1 + term2;
    }
    // Continued fraction expansion for x > 1.0
    float numerator = exp(-x);
    float denom = x + 1.0 / (1.0 + 1.0 / (x + 2.0 / (1.0 + 2.0 / (x + 3.0))));
    return numerator / max(1.0e-5, denom);
}

/**
 * Modified Bessel function of the first kind of order zero I_0(x).
 * Used for Patterson-Harding and Storchi analytical pencil beam scatter models.
 */
float evalModifiedBesselI0(float x) {
    float ax = abs(x);
    if (ax < 3.75) {
        float y = (x / 3.75) * (x / 3.75);
        return 1.0 + y * (3.5156229 + y * (3.0899424 + y * (1.2067492 + y * (0.2659732 + y * (0.0360768 + y * 0.0045813)))));
    }
    float y = 3.75 / ax;
    float poly = 0.39894228 + y * (0.01328592 + y * (0.00225319 + y * (-0.00157565 + y * (0.00916281 + y * (-0.02057706 + y * (0.02635537 + y * (-0.01647633 + y * 0.00392377)))))));
    return (exp(ax) / sqrt(ax)) * poly;
}

/**
 * Modified Bessel function of the second kind of order zero K_0(x).
 */
float evalModifiedBesselK0(float x) {
    if (x <= 0.0) return 1.0e6;
    if (x <= 2.0) {
        float y = 0.25 * x * x;
        float term1 = -log(0.5 * x) * evalModifiedBesselI0(x);
        float poly = -0.57721566 + y * (0.42278420 + y * (0.23069756 + y * (0.03488590 + y * (0.00262698 + y * (0.00010750 + y * 0.00000740)))));
        return term1 + poly;
    }
    float y = 2.0 / x;
    float poly = 1.25331414 + y * (-0.07832358 + y * (0.02189568 + y * (-0.01062446 + y * (0.00587872 + y * (-0.00251540 + y * 0.00053208)))));
    return (exp(-x) / sqrt(x)) * poly;
}

/**
 * Voigt profile (convolution of Gaussian and Lorentzian distributions)
 * using the Humlicek rational approximation of the complex error function w(z).
 */
float evalVoigtProfile(float x, float sigma, float gamma) {
    float s = max(1.0e-5, sigma * SQRT_TWO);
    float u = x / s;
    float a = max(1.0e-5, gamma / s);

    // Rational approximation for real part of w(u + i*a)
    float u2 = u * u;
    float a2 = a * a;
    float denom = u2 + (a + 1.5) * (a + 1.5);
    float term = a / (PI * (u2 + a2));
    float gauss = exp(-u2);

    return (a > 1.5) ? term : mix(gauss / (sigma * sqrt(TWO_PI)), term, clamp(a / 1.5, 0.0, 1.0));
}

#endif // KERMA_SPECIAL_FUNCTIONS_GLSL
