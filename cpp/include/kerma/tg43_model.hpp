#pragma once

#include <vector>
#include <string>
#include <cmath>
#include <array>

namespace kerma {

struct BrachySeed {
    std::array<float, 3> position_mm{0.0f, 0.0f, 0.0f};
    std::array<float, 3> orientation{0.0f, 0.0f, 1.0f}; // Unit vector along seed capsule axis
    float air_kerma_strength_u = 40700.0f; // Air kerma strength S_k in U = cGy cm^2 / h
    float active_length_mm = 3.6f;
    float dose_rate_constant = 1.109f; // Lambda in cGy / (h * U)
};

class TG43Calculator {
public:
    TG43Calculator() = default;

    // Evaluates absorbed dose rate in cGy/h at query point (x, y, z) in mm for a given seed
    static float evaluate_seed_dose_rate(const BrachySeed& seed, const std::array<float, 3>& point_mm);

    // Line source geometry factor G_L(r, theta) in cm^-2
    static float geometry_factor_line(float r_cm, float theta_rad, float active_length_cm);

    // Radial dose function g_L(r) for HDR Ir-192 polynomial fit
    static float radial_dose_function(float r_cm);

    // 2D anisotropy function F(r, theta) polynomial fit
    static float anisotropy_function(float r_cm, float theta_rad);

    // Evaluates cumulative dose across a phantom grid in Gray for a prescribed dwell time in seconds
    static void compute_lattice_dose(const std::vector<BrachySeed>& seeds,
                                     float dwell_time_seconds,
                                     const std::array<float, 3>& origin_mm,
                                     const std::array<float, 3>& spacing_mm,
                                     const std::array<int, 3>& dims,
                                     std::vector<float>& out_dose_grid_gy);
};

} // namespace kerma
