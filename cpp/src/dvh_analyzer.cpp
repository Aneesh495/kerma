#include "kerma/dvh_analyzer.hpp"
#include <cmath>
#include <algorithm>

namespace kerma {

DVHCurve analyze_dvh(const DoseGrid3D& dose, const VoxelVolume& phantom, int target_roi, float max_dose_scale_gy) {
    DVHCurve dvh;
    dvh.roi_id = target_roi;
    dvh.voxel_volume_cc = (phantom.dx_mm * phantom.dy_mm * phantom.dz_mm) * 1.0e-3f;

    const int num_bins = 1000;
    std::vector<int> differential_bins(num_bins, 0);
    float delta_dose = max_dose_scale_gy / static_cast<float>(num_bins);

    int total_voxels = 0;
    float sum_dose = 0.0f;
    float min_d = 1.0e6f;
    float max_d = 0.0f;

    for (int z = 0; z < phantom.nz; ++z) {
        for (int y = 0; y < phantom.ny; ++y) {
            for (int x = 0; x < phantom.nx; ++x) {
                size_t idx = phantom.index(x, y, z);
                if (phantom.roi_labels[idx] != target_roi) continue;

                total_voxels++;
                float d = dose.dose_gy[idx];
                sum_dose += d;
                if (d < min_d) min_d = d;
                if (d > max_d) max_d = d;

                int bin = static_cast<int>(d / delta_dose);
                bin = std::clamp(bin, 0, num_bins - 1);
                differential_bins[static_cast<size_t>(bin)]++;
            }
        }
    }

    dvh.total_structure_volume_cc = static_cast<float>(total_voxels) * dvh.voxel_volume_cc;
    dvh.d_mean_gy = (total_voxels > 0) ? (sum_dose / static_cast<float>(total_voxels)) : 0.0f;

    dvh.dose_bins_gy.resize(num_bins);
    dvh.cumulative_vol_pct.resize(num_bins, 0.0f);

    if (total_voxels == 0) {
        return dvh;
    }

    int accumulated_voxels = 0;
    for (int i = num_bins - 1; i >= 0; --i) {
        accumulated_voxels += differential_bins[static_cast<size_t>(i)];
        dvh.dose_bins_gy[static_cast<size_t>(i)] = static_cast<float>(i) * delta_dose;
        dvh.cumulative_vol_pct[static_cast<size_t>(i)] = (static_cast<float>(accumulated_voxels) / static_cast<float>(total_voxels)) * 100.0f;
    }

    // Helper to find dose at a given volume percentage
    auto dose_at_volume = [&](float target_pct) -> float {
        for (int i = 0; i < num_bins - 1; ++i) {
            float v1 = dvh.cumulative_vol_pct[static_cast<size_t>(i)];
            float v2 = dvh.cumulative_vol_pct[static_cast<size_t>(i + 1)];
            if (v1 >= target_pct && v2 <= target_pct) {
                float d1 = dvh.dose_bins_gy[static_cast<size_t>(i)];
                float d2 = dvh.dose_bins_gy[static_cast<size_t>(i + 1)];
                float frac = (std::abs(v1 - v2) > 1.0e-5f) ? ((v1 - target_pct) / (v1 - v2)) : 0.0f;
                return d1 + frac * (d2 - d1);
            }
        }
        return (dvh.cumulative_vol_pct[0] < target_pct) ? 0.0f : max_d;
    };

    // Helper to find volume percentage receiving at least a target dose
    auto volume_at_dose = [&](float target_gy) -> float {
        if (target_gy <= 0.0f) return 100.0f;
        int idx = static_cast<int>(target_gy / delta_dose);
        if (idx >= num_bins - 1) return 0.0f;
        idx = std::clamp(idx, 0, num_bins - 1);
        return dvh.cumulative_vol_pct[static_cast<size_t>(idx)];
    };

    dvh.d98_gy = dose_at_volume(98.0f);
    dvh.d95_gy = dose_at_volume(95.0f);
    dvh.d50_gy = dose_at_volume(50.0f);
    dvh.d2_gy  = dose_at_volume(2.0f);

    dvh.v20_pct = volume_at_dose(20.0f);
    dvh.v50_pct = volume_at_dose(50.0f);

    dvh.homogeneity_index = (dvh.d50_gy > 0.01f) ? ((dvh.d2_gy - dvh.d98_gy) / dvh.d50_gy) : 0.0f;

    return dvh;
}

} // namespace kerma
