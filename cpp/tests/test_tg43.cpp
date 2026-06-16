#include "kerma/tg43_model.hpp"
#include <iostream>
#include <cassert>
#include <cmath>

namespace kerma {

void run_tg43_tests() {
    std::cout << "[TEST] Running TG-43 Brachytherapy Model Tests..." << std::endl;

    // Test 1: Geometry factor limit at 1 cm transverse axis
    float g_line_1cm = TG43Calculator::geometry_factor_line(1.0f, 1.5707963f, 0.36f);
    assert(g_line_1cm > 0.95f && g_line_1cm < 1.05f);

    // Test 2: Radial dose function at r = 1.0 cm should be exactly ~1.000
    float g_r_1cm = TG43Calculator::radial_dose_function(1.0f);
    assert(std::abs(g_r_1cm - 1.0f) < 0.01f);

    // Test 3: Anisotropy function at transverse axis (theta = 90 deg) should be 1.0
    float f_90 = TG43Calculator::anisotropy_function(1.0f, 1.5707963f);
    assert(std::abs(f_90 - 1.0f) < 1e-4f);

    // Test 4: Anisotropy along longitudinal axis (theta = 0 deg) should exhibit attenuation (< 0.70)
    float f_0 = TG43Calculator::anisotropy_function(1.0f, 0.0f);
    assert(f_0 < 0.70f);

    // Test 5: Reference dose rate at (0, 10mm, 0) for standard seed
    BrachySeed seed;
    seed.position_mm = {0.0f, 0.0f, 0.0f};
    seed.orientation = {0.0f, 0.0f, 1.0f};
    seed.air_kerma_strength_u = 40700.0f; // ~10 Ci HDR Ir-192
    seed.dose_rate_constant = 1.109f;

    std::array<float, 3> ref_pt{0.0f, 10.0f, 0.0f}; // 1 cm transverse
    float rate_cgy_h = TG43Calculator::evaluate_seed_dose_rate(seed, ref_pt);

    // Theoretical reference dose rate: S_k * Lambda * 1.0 * 1.0 * 1.0 = 40700 * 1.109 = 45136.3 cGy/h
    float expected_rate = 40700.0f * 1.109f;
    float rel_diff = std::abs(rate_cgy_h - expected_rate) / expected_rate;
    assert(rel_diff < 0.02f);

    // Test 6: 3D lattice calculation
    std::vector<BrachySeed> seeds = {seed};
    std::vector<float> dose_grid;
    TG43Calculator::compute_lattice_dose(seeds, 10.0f, {-10.0f, -10.0f, -10.0f}, {5.0f, 5.0f, 5.0f}, {5, 5, 5}, dose_grid);
    assert(dose_grid.size() == 125);
    // Center voxel should have positive dose
    assert(dose_grid[62] > 0.0f);

    std::cout << "[PASS] All TG-43 Brachytherapy Tests Passed!" << std::endl;
}

} // namespace kerma
