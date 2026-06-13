#include "kerma/tg43_model.hpp"
#include <algorithm>
#include <cmath>

namespace kerma {

static constexpr float PI = 3.14159265358979323846f;

float TG43Calculator::geometry_factor_line(float r_cm, float theta_rad, float active_length_cm) {
    if (r_cm <= 1e-4f) {
        return 1.0e6f;
    }
    float l = active_length_cm;
    if (l <= 1e-4f) {
        // Point source limit G_P(r) = 1 / r^2
        return 1.0f / (r_cm * r_cm);
    }

    float sin_theta = std::sin(theta_rad);
    if (std::abs(sin_theta) < 1e-4f) {
        // Along capsule axis: G_L(r, 0) = 1.0 / (r^2 - (L/2)^2)
        float denom = r_cm * r_cm - 0.25f * l * l;
        if (denom <= 1e-5f) {
            denom = 1e-5f;
        }
        return 1.0f / denom;
    }

    // Line source angle beta subtended by active core
    float y_over_r = std::cos(theta_rad);
    float beta1 = std::atan2(r_cm * sin_theta, r_cm * y_over_r - 0.5f * l);
    float beta2 = std::atan2(r_cm * sin_theta, r_cm * y_over_r + 0.5f * l);
    float beta = std::abs(beta1 - beta2);

    return beta / (l * r_cm * sin_theta);
}

float TG43Calculator::radial_dose_function(float r_cm) {
    // 5th order polynomial fit for HDR Ir-192 in water (0.25 cm to 10 cm)
    // g_L(r) = a0 + a1*r + a2*r^2 + a3*r^3 + a4*r^4 + a5*r^5
    if (r_cm < 0.1f) return 1.008f;
    if (r_cm > 15.0f) return 0.50f;

    const float a0 =  1.0084f;
    const float a1 = -0.0072f;
    const float a2 = -0.0003f;
    const float a3 = -0.0001f;
    const float a4 =  0.00001f;

    float r = r_cm;
    return a0 + a1 * r + a2 * r * r + a3 * r * r * r + a4 * r * r * r * r;
}

float TG43Calculator::anisotropy_function(float r_cm, float theta_rad) {
    (void)r_cm;
    // 2D anisotropy function approximation
    float deg = theta_rad * (180.0f / PI);
    if (deg > 180.0f) deg = 360.0f - deg;
    if (deg > 90.0f) deg = 180.0f - deg; // symmetric around transverse plane

    // Attenuation along longitudinal axis due to capsule end welds
    if (deg < 5.0f) return 0.63f;
    if (deg < 15.0f) return 0.78f;
    if (deg < 30.0f) return 0.90f;
    if (deg < 60.0f) return 0.98f;
    return 1.00f;
}

float TG43Calculator::evaluate_seed_dose_rate(const BrachySeed& seed, const std::array<float, 3>& point_mm) {
    // Vector from seed to query point in cm
    float rx_cm = (point_mm[0] - seed.position_mm[0]) * 0.1f;
    float ry_cm = (point_mm[1] - seed.position_mm[1]) * 0.1f;
    float rz_cm = (point_mm[2] - seed.position_mm[2]) * 0.1f;

    float r_cm = std::sqrt(rx_cm * rx_cm + ry_cm * ry_cm + rz_cm * rz_cm);
    if (r_cm < 0.05f) {
        r_cm = 0.05f; // Physical seed radius cutoff
    }

    // Polar angle theta relative to seed orientation vector
    float dot = (rx_cm * seed.orientation[0] + ry_cm * seed.orientation[1] + rz_cm * seed.orientation[2]) / r_cm;
    dot = std::clamp(dot, -1.0f, 1.0f);
    float theta_rad = std::acos(dot);

    float l_cm = seed.active_length_mm * 0.1f;
    float g_l_r_theta = geometry_factor_line(r_cm, theta_rad, l_cm);
    float g_l_r0_theta0 = geometry_factor_line(1.0f, 0.5f * PI, l_cm);
    float g_ratio = g_l_r_theta / std::max(g_l_r0_theta0, 1e-5f);

    float g_r = radial_dose_function(r_cm);
    float f_r_theta = anisotropy_function(r_cm, theta_rad);

    // Dose rate in cGy/h = S_k * Lambda * (G_L(r, theta) / G_L(1, pi/2)) * g_L(r) * F(r, theta)
    return seed.air_kerma_strength_u * seed.dose_rate_constant * g_ratio * g_r * f_r_theta;
}

void TG43Calculator::compute_lattice_dose(const std::vector<BrachySeed>& seeds,
                                         float dwell_time_seconds,
                                         const std::array<float, 3>& origin_mm,
                                         const std::array<float, 3>& spacing_mm,
                                         const std::array<int, 3>& dims,
                                         std::vector<float>& out_dose_grid_gy) {
    size_t total_voxels = static_cast<size_t>(dims[0]) * dims[1] * dims[2];
    out_dose_grid_gy.assign(total_voxels, 0.0f);

    float dwell_hours = dwell_time_seconds / 3600.0f;
    float cgy_to_gy = 0.01f;

    for (int z = 0; z < dims[2]; ++z) {
        float pz = origin_mm[2] + z * spacing_mm[2];
        for (int y = 0; y < dims[1]; ++y) {
            float py = origin_mm[1] + y * spacing_mm[1];
            for (int x = 0; x < dims[0]; ++x) {
                float px = origin_mm[0] + x * spacing_mm[0];
                std::array<float, 3> pt{px, py, pz};

                float total_rate_cgy_h = 0.0f;
                for (const auto& seed : seeds) {
                    total_rate_cgy_h += evaluate_seed_dose_rate(seed, pt);
                }

                size_t idx = static_cast<size_t>(z) * dims[1] * dims[0] + static_cast<size_t>(y) * dims[0] + x;
                out_dose_grid_gy[idx] = total_rate_cgy_h * dwell_hours * cgy_to_gy;
            }
        }
    }
}

} // namespace kerma
