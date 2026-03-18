#include "kerma/analytical_dose.hpp"
#include <cassert>
#include <iostream>

void test_pbc_calculation() {
    kerma::VoxelVolume phantom = kerma::create_synthetic_phantom(kerma::PhantomType::WaterCube, 24, 24, 24, 5.0f);
    kerma::BeamParameters beam;
    beam.monitor_units = 100.0f;
    beam.jaw_x1_mm = -30.0f;
    beam.jaw_x2_mm =  30.0f;
    beam.jaw_y1_mm = -30.0f;
    beam.jaw_y2_mm =  30.0f;

    kerma::DoseGrid3D dose = kerma::compute_analytical_pbc_dose(phantom, beam);
    float max_d = dose.max_dose();
    assert(max_d > 0.5f);
    assert(max_d < 2.0f); // 100 MU delivered dose is around 1 Gy
    std::cout << "[PASS] test_pbc_calculation (Max dose = " << max_d << " Gy)" << std::endl;
}

void test_bragg_peak() {
    auto curve = kerma::compute_bortfeld_bragg_curve(150.0f, 0.005f, 200, 200.0f);
    assert(curve.size() == 200);

    // Peak should occur near range = 150 mm (index 150)
    int peak_idx = 0;
    float peak_val = 0.0f;
    for (size_t i = 0; i < curve.size(); ++i) {
        if (curve[i] > peak_val) {
            peak_val = curve[i];
            peak_idx = static_cast<int>(i);
        }
    }
    assert(peak_idx >= 140 && peak_idx <= 160);
    std::cout << "[PASS] test_bragg_peak (Peak at bin " << peak_idx << ")" << std::endl;
}

void run_analytical_dose_tests() {
    test_pbc_calculation();
    test_bragg_peak();
    std::cout << "[ALL PASS] Analytical dose verification suite completed." << std::endl;
}
