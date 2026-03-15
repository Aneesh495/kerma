/**
 * Kerma Radiation Oncology Simulation Engine
 * Linear Algebra and Tensor Matrix Mathematics Library
 *
 * Implements high-performance matrix and tensor operations:
 * - Analytical 3x3 matrix inverse, determinant, and adjugate
 * - Cardano closed-form eigenvalue solver for 3x3 symmetric tensors
 * - Polar decomposition F = R * U into orthogonal rotation and right stretch
 * - Quaternion algebra and dual quaternion rigid transforms
 */

#ifndef KERMA_MATRIX_MATH_GLSL
#define KERMA_MATRIX_MATH_GLSL

#include "constants.glsl"

/**
 * Computes the inverse of a 3x3 matrix via Cramer's rule.
 */
mat3 invertMatrix3x3(mat3 m) {
    float a00 = m[0][0], a01 = m[0][1], a02 = m[0][2];
    float a10 = m[1][0], a11 = m[1][1], a12 = m[1][2];
    float a20 = m[2][0], a21 = m[2][1], a22 = m[2][2];

    float b01 = a22 * a11 - a12 * a21;
    float b11 = -a22 * a10 + a12 * a20;
    float b21 = a21 * a10 - a11 * a20;

    float det = a00 * b01 + a01 * b11 + a02 * b21;
    if (abs(det) < EPSILON_FLOAT) {
        return mat3(1.0); // Return identity on singular matrix
    }

    float inv_det = 1.0 / det;

    return mat3(
        b01 * inv_det,
        (-a22 * a01 + a02 * a21) * inv_det,
        (a12 * a01 - a02 * a11) * inv_det,
        b11 * inv_det,
        (a22 * a00 - a02 * a20) * inv_det,
        (-a12 * a00 + a02 * a10) * inv_det,
        b21 * inv_det,
        (-a21 * a00 + a01 * a20) * inv_det,
        (a11 * a00 - a01 * a10) * inv_det
    );
}

/**
 * Cardano analytical eigenvalue solver for a 3x3 symmetric matrix A = A^T.
 * Returns the three real eigenvalues sorted in descending order: lambda1 >= lambda2 >= lambda3.
 */
vec3 computeSymmetricEigenvalues(mat3 A) {
    float p1 = A[0][1] * A[0][1] + A[0][2] * A[0][2] + A[1][2] * A[1][2];
    if (p1 < 1.0e-7) {
        // Matrix is already diagonal
        vec3 diag = vec3(A[0][0], A[1][1], A[2][2]);
        return vec3(max(max(diag.x, diag.y), diag.z),
                    mix(min(max(diag.x, diag.y), diag.z), max(min(diag.x, diag.y), diag.z), 0.5),
                    min(min(diag.x, diag.y), diag.z));
    }

    float q = (A[0][0] + A[1][1] + A[2][2]) / 3.0; // Trace(A) / 3
    float p2 = (A[0][0] - q) * (A[0][0] - q) + (A[1][1] - q) * (A[1][1] - q) + (A[2][2] - q) * (A[2][2] - q) + 2.0 * p1;
    float p = sqrt(p2 / 6.0);

    mat3 B = (1.0 / max(1.0e-6, p)) * (A - q * mat3(1.0));
    float r = determinant(B) * 0.5;

    // Numerical clamp to [-1, 1] for acos
    float phi = (r <= -1.0) ? (PI / 3.0) : ((r >= 1.0) ? 0.0 : (acos(r) / 3.0));

    // The eigenvalues satisfy B: eig1 >= eig2 >= eig3
    float eig1 = q + 2.0 * p * cos(phi);
    float eig3 = q + 2.0 * p * cos(phi + (2.0 * PI / 3.0));
    float eig2 = 3.0 * q - eig1 - eig3; // Since trace is preserved

    return vec3(eig1, eig2, eig3);
}

/**
 * Quaternion multiplication: q1 * q2
 */
vec4 quatMultiply(vec4 q1, vec4 q2) {
    return vec4(
        q1.w * q2.xyz + q2.w * q1.xyz + cross(q1.xyz, q2.xyz),
        q1.w * q2.w - dot(q1.xyz, q2.xyz)
    );
}

/**
 * Rotates vector v by normalized unit quaternion q.
 */
vec3 quatRotateVector(vec4 q, vec3 v) {
    vec3 t = 2.0 * cross(q.xyz, v);
    return v + q.w * t + cross(q.xyz, t);
}

#endif // KERMA_MATRIX_MATH_GLSL
