#include "kerma/analytical_dose.hpp"
#include <cmath>
#include <algorithm>

namespace kerma {

constexpr float PI_F = 3.14159265358979323846f;
constexpr float DEG_TO_RAD_F = PI_F / 180.0f;

DoseGrid3D compute_analytical_pbc_dose(const VoxelVolume& phantom, const BeamParameters& beam) {
    DoseGrid3D dose;
    dose.nx = phantom.nx;
    dose.ny = phantom.ny;
    dose.nz = phantom.nz;
    dose.dx_mm = phantom.dx_mm;
    dose.dy_mm = phantom.dy_mm;
    dose.dz_mm = phantom.dz_mm;
    dose.origin_x_mm = phantom.origin_x_mm;
    dose.origin_y_mm = phantom.origin_y_mm;
    dose.origin_z_mm = phantom.origin_z_mm;

    size_t total_voxels = static_cast<size_t>(phantom.nx * phantom.ny * phantom.nz);
    dose.dose_gy.resize(total_voxels, 0.0f);

    Vec3 source_pos = compute_source_world_position(beam);

    // Gantry rotation terms
    float g_rad = beam.gantry_angle_deg * DEG_TO_RAD_F;
    float cos_g = std::cos(g_rad);
    float sin_g = std::sin(g_rad);

    float d_max_mm = 15.0f; // 6 MV d_max in water ~1.5 cm
    float mu_eff = 0.045f * 0.1f; // ~0.0045 mm^-1

    for (int z = 0; z < phantom.nz; ++z) {
        float pz = phantom.origin_z_mm + (static_cast<float>(z) + 0.5f) * phantom.dz_mm;
        for (int y = 0; y < phantom.ny; ++y) {
            float py = phantom.origin_y_mm + (static_cast<float>(y) + 0.5f) * phantom.dy_mm;
            for (int x = 0; x < phantom.nx; ++x) {
                float px = phantom.origin_x_mm + (static_cast<float>(x) + 0.5f) * phantom.dx_mm;
                size_t idx = phantom.index(x, y, z);

                float rho = phantom.mass_density[idx];
                if (rho < 0.05f) {
                    continue; // Skip ambient air outside phantom
                }

                Vec3 pt{px, py, pz};
                Vec3 ray_vec = pt - source_pos;
                float dist_source = ray_vec.length();
                if (dist_source < 10.0f) continue;

                // Transform to BEV coordinates
                Vec3 d = pt - beam.isocenter_mm;
                float bev_x =  d.x * cos_g - d.z * sin_g;
                float bev_y =  d.y;
                float bev_z =  d.x * sin_g + d.z * cos_g;

                float z_from_source = beam.sad_mm + bev_z;
                if (z_from_source <= 10.0f) continue;

                float scale = beam.sad_mm / z_from_source;
                float u_mm = bev_x * scale;
                float v_mm = bev_y * scale;

                // Inside jaw aperture check
                if (u_mm < beam.jaw_x1_mm || u_mm > beam.jaw_x2_mm ||
                    v_mm < beam.jaw_y1_mm || v_mm > beam.jaw_y2_mm) {
                    // Collimator leakage dose under jaws (~0.5%)
                    dose.dose_gy[idx] = 0.005f * (beam.monitor_units * 0.01f);
                    continue;
                }

                // Inverse square factor
                float inv_sq = (beam.sad_mm / dist_source) * (beam.sad_mm / dist_source);

                // Approximate radiological depth: assume phantom entry around surface
                float geom_depth = std::max(0.0f, bev_z + 75.0f); // Depth from anterior entrance
                float d_eff = geom_depth * phantom.rho_e[idx];

                // PDD curve
                float pdd = 0.0f;
                if (d_eff <= d_max_mm) {
                    float frac = std::max(0.0f, d_eff / d_max_mm);
                    pdd = 0.45f + 0.55f * std::sqrt(frac);
                } else {
                    pdd = std::exp(-mu_eff * (d_eff - d_max_mm));
                }

                // Absorbed dose in Gray: 1 cGy per MU at d_max at SAD = 100 cm
                float delivered_gy = pdd * inv_sq * (beam.monitor_units * 0.01f);
                dose.dose_gy[idx] = delivered_gy;
            }
        }
    }

    return dose;
}

std::vector<float> compute_bortfeld_bragg_curve(float range_r0_mm, float energy_spread, int samples, float max_depth_mm) {
    std::vector<float> curve(static_cast<size_t>(samples), 0.0f);
    float delta_z = max_depth_mm / static_cast<float>(samples);

    float sigma_mono = 0.012f * std::pow(std::max(1.0f, range_r0_mm), 0.935f);
    float sigma_spread = energy_spread * range_r0_mm * 1.5f;
    float sigma = std::sqrt(sigma_mono * sigma_mono + sigma_spread * sigma_spread);

    for (int i = 0; i < samples; ++i) {
        float z = (static_cast<float>(i) + 0.5f) * delta_z;
        float diff = range_r0_mm - z;
        float zeta = diff / std::max(0.1f, sigma);

        float d = 0.0f;
        if (z < range_r0_mm - 3.0f * sigma) {
            float z_norm = z / range_r0_mm;
            d = 1.0f / std::pow(std::max(0.01f, 1.0f - z_norm), 1.0f - 1.0f / 1.77f);
        } else if (z <= range_r0_mm + 4.0f * sigma) {
            float peak = 4.0f / std::sqrt(std::max(0.1f, sigma));
            d = peak * std::exp(-0.5f * zeta * zeta);
        } else {
            d = 0.001f * std::exp(-(z - range_r0_mm) / 10.0f);
        }
        curve[static_cast<size_t>(i)] = d;
    }
    return curve;
}

DoseGrid3D compute_tg43_seed_dose(const VoxelVolume& phantom, const Vec3& seed_pos, float air_kerma_strength_sk, float dwell_seconds) {
    DoseGrid3D dose;
    dose.nx = phantom.nx;
    dose.ny = phantom.ny;
    dose.nz = phantom.nz;
    dose.dx_mm = phantom.dx_mm;
    dose.dy_mm = phantom.dy_mm;
    dose.dz_mm = phantom.dz_mm;
    dose.origin_x_mm = phantom.origin_x_mm;
    dose.origin_y_mm = phantom.origin_y_mm;
    dose.origin_z_mm = phantom.origin_z_mm;

    size_t total_voxels = static_cast<size_t>(phantom.nx * phantom.ny * phantom.nz);
    dose.dose_gy.resize(total_voxels, 0.0f);

    float dose_rate_const = 1.108f; // cGy / h / U for Ir-192
    float dwell_hours = dwell_seconds / 3600.0f;

    for (int z = 0; z < phantom.nz; ++z) {
        float pz = phantom.origin_z_mm + (static_cast<float>(z) + 0.5f) * phantom.dz_mm;
        for (int y = 0; y < phantom.ny; ++y) {
            float py = phantom.origin_y_mm + (static_cast<float>(y) + 0.5f) * phantom.dy_mm;
            for (int x = 0; x < phantom.nx; ++x) {
                float px = phantom.origin_x_mm + (static_cast<float>(x) + 0.5f) * phantom.dx_mm;
                size_t idx = phantom.index(x, y, z);

                Vec3 pt{px, py, pz};
                Vec3 d = pt - seed_pos;
                float r_mm = std::max(0.5f, d.length());
                float r_cm = r_mm * 0.1f;

                // Point source inverse-square geometry factor: G(r) = 1 / r^2
                float g_ratio = 1.0f / (r_cm * r_cm);

                // Ir-192 radial dose function g(r)
                float g_l = 0.989f + 0.0125f * r_cm - 0.0035f * r_cm * r_cm;

                float dose_rate_cgy_h = air_kerma_strength_sk * dose_rate_const * g_ratio * g_l;
                float dose_gy = (dose_rate_cgy_h * 0.01f) * dwell_hours;

                dose.dose_gy[idx] = dose_gy;
            }
        }
    }

    return dose;
}

} // namespace kerma
