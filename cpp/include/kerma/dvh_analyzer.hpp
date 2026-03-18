#ifndef KERMA_DVH_ANALYZER_HPP
#define KERMA_DVH_ANALYZER_HPP

#include "phantom.hpp"
#include "analytical_dose.hpp"
#include <vector>

namespace kerma {

struct DVHCurve {
    int roi_id = 1;
    float voxel_volume_cc = 0.0f;
    float total_structure_volume_cc = 0.0f;
    std::vector<float> dose_bins_gy;      // Dose axis (e.g. 0 to 80 Gy in 0.1 Gy steps)
    std::vector<float> cumulative_vol_pct;// V(>= D) in percent [0, 100]

    // Clinical dosimetry indices
    float d98_gy = 0.0f;  // Near-minimum dose
    float d95_gy = 0.0f;  // Prescription coverage dose
    float d50_gy = 0.0f;  // Median dose
    float d2_gy  = 0.0f;  // Near-maximum dose (hot spot)
    float d_mean_gy = 0.0f;
    float v20_pct = 0.0f; // Percent volume receiving >= 20 Gy
    float v50_pct = 0.0f; // Percent volume receiving >= 50 Gy
    float homogeneity_index = 0.0f; // (D2 - D98) / D50
};

/**
 * Computes cumulative DVH and extracts clinical metrics for specified ROI.
 */
DVHCurve analyze_dvh(const DoseGrid3D& dose, const VoxelVolume& phantom, int target_roi, float max_dose_scale_gy = 80.0f);

} // namespace kerma

#endif // KERMA_DVH_ANALYZER_HPP
