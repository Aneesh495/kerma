#include "kerma/gamma_evaluation.hpp"
#include <cmath>
#include <algorithm>

namespace kerma {

GammaResult evaluate_gamma_3d(const DoseGrid3D& evaluated, const DoseGrid3D& reference, const GammaParameters& params) {
    GammaResult result;
    size_t total_voxels = static_cast<size_t>(reference.nx * reference.ny * reference.nz);
    result.gamma_map.resize(total_voxels, 0.0f);

    float max_ref_dose = reference.max_dose();
    float dose_threshold = (params.threshold_percent * 0.01f) * max_ref_dose;

    float inv_dta_sq = 1.0f / (params.dta_mm * params.dta_mm);
    float global_delta_d = (params.dose_diff_percent * 0.01f) * max_ref_dose;
    float global_inv_dd_sq = 1.0f / (global_delta_d * global_delta_d);

    float gamma_sum = 0.0f;
    float max_g = 0.0f;
    int eval_count = 0;
    int pass_count = 0;

    int r = params.search_radius_voxels;

    for (int z = 0; z < reference.nz; ++z) {
        for (int y = 0; y < reference.ny; ++y) {
            for (int x = 0; x < reference.nx; ++x) {
                size_t idx_m = reference.index(x, y, z);
                float d_m = reference.dose_gy[idx_m];

                // Suppress low-dose background
                if (d_m < dose_threshold) {
                    result.gamma_map[idx_m] = 0.0f;
                    continue;
                }

                eval_count++;

                float inv_dd_sq = global_inv_dd_sq;
                if (params.use_local_gamma) {
                    float local_dd = (params.dose_diff_percent * 0.01f) * std::max(0.01f, d_m);
                    inv_dd_sq = 1.0f / (local_dd * local_dd);
                }

                float min_gamma_sq = 1.0e8f;

                int z_min = std::max(0, z - r);
                int z_max = std::min(reference.nz - 1, z + r);
                int y_min = std::max(0, y - r);
                int y_max = std::min(reference.ny - 1, y + r);
                int x_min = std::max(0, x - r);
                int x_max = std::min(reference.nx - 1, x + r);

                for (int cz = z_min; cz <= z_max; ++cz) {
                    float dz_mm = static_cast<float>(cz - z) * reference.dz_mm;
                    float dz2 = dz_mm * dz_mm;
                    for (int cy = y_min; cy <= y_max; ++cy) {
                        float dy_mm = static_cast<float>(cy - y) * reference.dy_mm;
                        float dy2 = dy_mm * dy_mm;
                        for (int cx = x_min; cx <= x_max; ++cx) {
                            float dx_mm = static_cast<float>(cx - x) * reference.dx_mm;
                            float dist_sq = dx_mm * dx_mm + dy2 + dz2;
                            float dist_term = dist_sq * inv_dta_sq;

                            if (dist_term >= min_gamma_sq) continue;

                            float d_c = evaluated.get(cx, cy, cz);
                            float diff = d_m - d_c;
                            float dose_term = (diff * diff) * inv_dd_sq;

                            float g_sq = dist_term + dose_term;
                            if (g_sq < min_gamma_sq) {
                                min_gamma_sq = g_sq;
                            }
                        }
                    }
                }

                float gamma_val = std::sqrt(min_gamma_sq);
                result.gamma_map[idx_m] = gamma_val;
                gamma_sum += gamma_val;
                if (gamma_val > max_g) max_g = gamma_val;
                if (gamma_val <= 1.0f) pass_count++;
            }
        }
    }

    result.total_evaluated_voxels = eval_count;
    result.passing_voxels = pass_count;
    result.mean_gamma = (eval_count > 0) ? (gamma_sum / static_cast<float>(eval_count)) : 0.0f;
    result.max_gamma = max_g;
    result.pass_rate_percent = (eval_count > 0) ? (100.0f * static_cast<float>(pass_count) / static_cast<float>(eval_count)) : 0.0f;

    return result;
}

} // namespace kerma
