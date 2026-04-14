// Lebedev Spherical Quadrature Grid Generator and Hardcoded High-Order Tables
// Reference: V. I. Lebedev, "A quadrature formula for the sphere of 59th algebraic degree of accuracy"
// Russ. Acad. Sci. Dokl. Math., 1995.
// Integrates spherical harmonics Y_lm exactly on S^2 for order l <= L_max

#ifndef LEBEDEV_QUADRATURES_GLSL
#define LEBEDEV_QUADRATURES_GLSL

struct QuadratureRay {
    vec3 direction;
    float weight;
    float solid_angle;
};

// Lebedev Order 6 (6 points: octahedron vertices)
// Exact up to algebraic degree 3
void get_lebedev_order_6(in uint index, out vec3 dir, out float weight) {
    const float w = 1.0f / 6.0f;
    weight = w;
    switch (index) {
        case 0u: dir = vec3( 1.0f,  0.0f,  0.0f); break;
        case 1u: dir = vec3(-1.0f,  0.0f,  0.0f); break;
        case 2u: dir = vec3( 0.0f,  1.0f,  0.0f); break;
        case 3u: dir = vec3( 0.0f, -1.0f,  0.0f); break;
        case 4u: dir = vec3( 0.0f,  0.0f,  1.0f); break;
        default: dir = vec3( 0.0f,  0.0f, -1.0f); break;
    }
}

// Lebedev Order 14 (14 points: 6 octahedron + 8 cube vertices)
// Exact up to algebraic degree 5
void get_lebedev_order_14(in uint index, out vec3 dir, out float weight) {
    const float a = 0.577350269189626f; // 1 / sqrt(3)
    const float w1 = 0.066666666666667f; // 6 points
    const float w2 = 0.075000000000000f; // 8 points

    if (index < 6u) {
        weight = w1;
        switch (index) {
            case 0u: dir = vec3( 1.0f,  0.0f,  0.0f); break;
            case 1u: dir = vec3(-1.0f,  0.0f,  0.0f); break;
            case 2u: dir = vec3( 0.0f,  1.0f,  0.0f); break;
            case 3u: dir = vec3( 0.0f, -1.0f,  0.0f); break;
            case 4u: dir = vec3( 0.0f,  0.0f,  1.0f); break;
            default: dir = vec3( 0.0f,  0.0f, -1.0f); break;
        }
    } else {
        weight = w2;
        uint sub = index - 6u;
        float sx = (sub & 1u) != 0u ? -a : a;
        float sy = (sub & 2u) != 0u ? -a : a;
        float sz = (sub & 4u) != 0u ? -a : a;
        dir = vec3(sx, sy, sz);
    }
}

// Lebedev Order 26 (26 points: 6 octahedron + 8 cube + 12 rhombic dodecahedron vertices)
// Exact up to algebraic degree 7
void get_lebedev_order_26(in uint index, out vec3 dir, out float weight) {
    const float a = 0.577350269189626f; // 1 / sqrt(3)
    const float b = 0.707106781186548f; // 1 / sqrt(2)
    const float w1 = 0.047619047619048f; // 6 points: (1, 0, 0)
    const float w2 = 0.038095238095238f; // 8 points: (a, a, a)
    const float w3 = 0.034285714285714f; // 12 points: (b, b, 0)

    if (index < 6u) {
        weight = w1;
        switch (index) {
            case 0u: dir = vec3( 1.0f,  0.0f,  0.0f); break;
            case 1u: dir = vec3(-1.0f,  0.0f,  0.0f); break;
            case 2u: dir = vec3( 0.0f,  1.0f,  0.0f); break;
            case 3u: dir = vec3( 0.0f, -1.0f,  0.0f); break;
            case 4u: dir = vec3( 0.0f,  0.0f,  1.0f); break;
            default: dir = vec3( 0.0f,  0.0f, -1.0f); break;
        }
    } else if (index < 14u) {
        weight = w2;
        uint sub = index - 6u;
        float sx = (sub & 1u) != 0u ? -a : a;
        float sy = (sub & 2u) != 0u ? -a : a;
        float sz = (sub & 4u) != 0u ? -a : a;
        dir = vec3(sx, sy, sz);
    } else {
        weight = w3;
        uint sub = index - 14u;
        // 12 permutations of (+/- b, +/- b, 0)
        switch (sub) {
            case 0u:  dir = vec3( b,  b, 0.0f); break;
            case 1u:  dir = vec3( b, -b, 0.0f); break;
            case 2u:  dir = vec3(-b,  b, 0.0f); break;
            case 3u:  dir = vec3(-b, -b, 0.0f); break;
            case 4u:  dir = vec3( b, 0.0f,  b); break;
            case 5u:  dir = vec3( b, 0.0f, -b); break;
            case 6u:  dir = vec3(-b, 0.0f,  b); break;
            case 7u:  dir = vec3(-b, 0.0f, -b); break;
            case 8u:  dir = vec3(0.0f,  b,  b); break;
            case 9u:  dir = vec3(0.0f,  b, -b); break;
            case 10u: dir = vec3(0.0f, -b,  b); break;
            default:  dir = vec3(0.0f, -b, -b); break;
        }
    }
}

// Lebedev Order 38 (38 points)
// Exact up to algebraic degree 9
void get_lebedev_order_38(in uint index, out vec3 dir, out float weight) {
    const float a1 = 0.577350269189626f;
    const float u1 = 0.881917103688197f;
    const float v1 = 0.333333333333333f;
    
    const float w1 = 0.009523809523810f; // 6 points
    const float w2 = 0.032142857142857f; // 8 points
    const float w3 = 0.028571428571429f; // 24 points

    if (index < 6u) {
        weight = w1;
        switch (index) {
            case 0u: dir = vec3( 1.0f,  0.0f,  0.0f); break;
            case 1u: dir = vec3(-1.0f,  0.0f,  0.0f); break;
            case 2u: dir = vec3( 0.0f,  1.0f,  0.0f); break;
            case 3u: dir = vec3( 0.0f, -1.0f,  0.0f); break;
            case 4u: dir = vec3( 0.0f,  0.0f,  1.0f); break;
            default: dir = vec3( 0.0f,  0.0f, -1.0f); break;
        }
    } else if (index < 14u) {
        weight = w2;
        uint sub = index - 6u;
        float sx = (sub & 1u) != 0u ? -a1 : a1;
        float sy = (sub & 2u) != 0u ? -a1 : a1;
        float sz = (sub & 4u) != 0u ? -a1 : a1;
        dir = vec3(sx, sy, sz);
    } else {
        weight = w3;
        uint sub = index - 14u;
        uint perm = sub / 8u; // 0, 1, 2
        uint sign_bits = sub % 8u;
        float s1 = (sign_bits & 1u) != 0u ? -u1 : u1;
        float s2 = (sign_bits & 2u) != 0u ? -v1 : v1;
        float s3 = (sign_bits & 4u) != 0u ? -v1 : v1;

        if (perm == 0u) {
            dir = vec3(s1, s2, s3);
        } else if (perm == 1u) {
            dir = vec3(s2, s1, s3);
        } else {
            dir = vec3(s2, s3, s1);
        }
    }
}

// Generalized lookup function for spherical integration
QuadratureRay get_spherical_quadrature_ray(uint scheme_order, uint ray_idx) {
    QuadratureRay ray;
    if (scheme_order == 6u) {
        get_lebedev_order_6(ray_idx % 6u, ray.direction, ray.weight);
    } else if (scheme_order == 14u) {
        get_lebedev_order_14(ray_idx % 14u, ray.direction, ray.weight);
    } else if (scheme_order == 26u) {
        get_lebedev_order_26(ray_idx % 26u, ray.direction, ray.weight);
    } else {
        get_lebedev_order_38(ray_idx % 38u, ray.direction, ray.weight);
    }
    // Solid angle normalized to 4 * pi
    ray.solid_angle = ray.weight * 4.0f * 3.14159265358979323846f;
    return ray;
}

#endif // LEBEDEV_QUADRATURES_GLSL
