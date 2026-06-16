#include "kerma/dvh_analyzer.hpp"
#include <iostream>
#include <cassert>
#include <cmath>

namespace kerma {

void run_dvh_tests() {
    std::cout << "[TEST] Running DVH Analyzer and Clinical Metrics Tests..." << std::endl;

    // Create a 10x10x10 phantom
    VoxelVolume phantom;
    phantom.nx = 10;
    phantom.ny = 10;
    phantom.nz = 10;
    phantom.dx_mm = 2.0f;
    phantom.dy_mm = 2.0f;
    phantom.dz_mm = 2.0f;
    phantom.hu_data.assign(1000, 0.0f);
    phantom.mass_density.assign(1000, 1.0f);
    phantom.rho_e.assign(1000, 1.0f);
    phantom.roi_labels.assign(1000, 1); // ROI 1

    // Create a uniform dose grid of 60.0 Gy
    DoseGrid3D dose;
    dose.nx = 10;
    dose.ny = 10;
    dose.nz = 10;
    dose.dx_mm = 2.0f;
    dose.dy_mm = 2.0f;
    dose.dz_mm = 2.0f;
    dose.dose_gy.assign(1000, 60.0f);

    DVHCurve dvh = analyze_dvh(dose, phantom, 1, 80.0f);

    // Voxel volume = 2*2*2 mm3 = 8 mm3 = 0.008 cc
    // Total structure volume = 1000 * 0.008 cc = 8.0 cc
    assert(std::abs(dvh.total_structure_volume_cc - 8.0f) < 1e-3f);

    // For a uniform 60 Gy distribution:
    // D98, D95, D50, D2, and D_mean should all be ~60 Gy
    assert(std::abs(dvh.d_mean_gy - 60.0f) < 0.5f);
    assert(std::abs(dvh.d50_gy - 60.0f) < 0.5f);
    assert(std::abs(dvh.d95_gy - 60.0f) < 0.5f);
    assert(std::abs(dvh.d2_gy - 60.0f) < 0.5f);

    // V20 and V50 should be 100%
    assert(std::abs(dvh.v20_pct - 100.0f) < 0.1f);
    assert(std::abs(dvh.v50_pct - 100.0f) < 0.1f);

    // Homogeneity index (D2 - D98) / D50 should be close to 0.0 for uniform dose
    assert(dvh.homogeneity_index < 0.05f);

    std::cout << "[PASS] All DVH Analyzer Tests Passed!" << std::endl;
}

} // namespace kerma
