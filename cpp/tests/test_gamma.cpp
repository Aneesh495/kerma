#include "kerma/gamma_evaluation.hpp"
#include <cassert>
#include <iostream>

void test_identical_dose_gamma() {
    kerma::DoseGrid3D ref;
    ref.nx = 16;
    ref.ny = 16;
    ref.nz = 16;
    ref.dose_gy.resize(16 * 16 * 16, 2.0f); // Uniform 2 Gy

    kerma::DoseGrid3D eval = ref;

    kerma::GammaParameters p;
    p.dose_diff_percent = 3.0f;
    p.dta_mm = 3.0f;
    p.threshold_percent = 10.0f;

    kerma::GammaResult res = kerma::evaluate_gamma_3d(eval, ref, p);
    assert(res.total_evaluated_voxels > 0);
    assert(res.pass_rate_percent >= 99.9f);
    assert(res.mean_gamma < 1.0e-3f);
    std::cout << "[PASS] test_identical_dose_gamma (Pass rate = " << res.pass_rate_percent << "%)" << std::endl;
}

void test_shifted_dose_gamma() {
    kerma::DoseGrid3D ref;
    ref.nx = 16;
    ref.ny = 16;
    ref.nz = 16;
    ref.dose_gy.resize(16 * 16 * 16, 2.0f);

    kerma::DoseGrid3D eval = ref;
    // Apply 20% dose error
    for (float& v : eval.dose_gy) {
        v *= 1.20f;
    }

    kerma::GammaParameters p;
    p.dose_diff_percent = 3.0f;
    p.dta_mm = 3.0f;
    p.threshold_percent = 10.0f;

    kerma::GammaResult res = kerma::evaluate_gamma_3d(eval, ref, p);
    // 20% error exceeds 3% tolerance, so gamma should fail
    assert(res.pass_rate_percent < 5.0f);
    std::cout << "[PASS] test_shifted_dose_gamma (Failed as expected, pass rate = " << res.pass_rate_percent << "%)" << std::endl;
}

void run_gamma_tests() {
    test_identical_dose_gamma();
    test_shifted_dose_gamma();
    std::cout << "[ALL PASS] Gamma index verification suite completed." << std::endl;
}
