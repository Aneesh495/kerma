#ifndef KERMA_GAMMA_EVALUATION_HPP
#define KERMA_GAMMA_EVALUATION_HPP

#include "analytical_dose.hpp"
#include <vector>

namespace kerma {

struct GammaResult {
    float pass_rate_percent = 0.0f; // Percent of tested voxels with gamma <= 1.0
    float mean_gamma = 0.0f;
    float max_gamma = 0.0f;
    int total_evaluated_voxels = 0;
    int passing_voxels = 0;
    std::vector<float> gamma_map;   // Voxelwise gamma values
};

struct GammaParameters {
    float dose_diff_percent = 3.0f; // 3%
    float dta_mm = 3.0f;            // 3 mm
    float threshold_percent = 10.0f;// 10% low-dose threshold
    bool  use_local_gamma = false;  // false = global normalization
    int   search_radius_voxels = 3;
};

/**
 * Evaluates Low's 3D Gamma Index comparing evaluated dose grid with reference dose grid.
 */
GammaResult evaluate_gamma_3d(const DoseGrid3D& evaluated, const DoseGrid3D& reference, const GammaParameters& params);

} // namespace kerma

#endif // KERMA_GAMMA_EVALUATION_HPP
